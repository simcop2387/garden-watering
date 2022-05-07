#!/usr/bin/env perl

use strict;
use warnings;
use Path::Tiny;
use Mojo::Template;
use Data::Section::Simple qw/get_data_section/;
use Time::Piece;

my $out_path=path("dist");
$out_path->mkpath();
my $out_file=$out_path->child("garden-watering.yaml");

my @pot_mapping = (
  {switch =>  1, name => "Pot  1", sensor => "0", default_water => 10, max_water => 25, status => 0},
  {switch =>  2, name => "Pot  2", sensor => "1", default_water => 10, max_water => 25, status => 1},
  {switch =>  3, name => "Pot  3", sensor => "2", default_water => 10, max_water => 25, status => 2},
  {switch =>  4, name => "Pot  4", sensor => "3", default_water => 10, max_water => 25, status => 3},
  {switch =>  5, name => "Pot  5", sensor => "4", default_water => 10, max_water => 25, status => 4},
  {switch =>  6, name => "Pot  6", sensor => "5", default_water => 10, max_water => 25, status => 5},
  {switch =>  7, name => "Pot  7", sensor => "6", default_water => 10, max_water => 25, status => 6},
  {switch =>  8, name => "Pot  8", sensor => "7", default_water => 10, max_water => 25, status => 7},
  {switch =>  9, name => "Pot  9", sensor => "8", default_water => 10, max_water => 25, status => 8},
  {switch => 10, name => "Pot 10", sensor => "9", default_water => 10, max_water => 25, status => 9},
  {switch => 11, name => "Pot 11", sensor => "10", default_water => 10, max_water => 25, status => 10},
  {switch => 12, name => "Pot 12", sensor => "11", default_water => 10, max_water => 25, status => 11},
  {switch => 13, name => "Pot 13", sensor => "12", default_water => 10, max_water => 25, status => 12},
  {switch => 14, name => "Pot 14", sensor => "13", default_water => 10, max_water => 25, status => 13},
  {switch => 15, name => "Pot 15", sensor => "14", default_water => 10, max_water => 25, status => 14},
);

for my $n (0..$#pot_mapping) {
  $pot_mapping[$n]{number} = $n
};

my $pump_mapping = 
  {switch => 0, name => "Pump Relay"};

my $analog_mux_pins = [qw/19 18 17 16/];

my %gpio_relay_map = (
 0 => 12,
 1 => 0,
 2 => 1,
 3 => 2,
 4 => 3,
 5 => 4,
 6 => 5,
 7 => 6,
 8 => 7,
 9 => 8,
 10 => 9,
 11 => 10,
 12 => 11,
 13 => 13,
 14 => 14,
 15 => 15
);

my $all = get_data_section;
my $mt = Mojo::Template->new();
$mt->name("garden-watering.yaml");
my $build_date = localtime->datetime();
my $out = $mt->vars(1)->render($all->{"garden-watering.yaml"}, {entries => \@pot_mapping, analog_mux_pins => $analog_mux_pins, gpio_relay_map => \%gpio_relay_map, pump_mapping => $pump_mapping, build_date=>$build_date});
$out_file->spew_utf8($out);
 
__END__
__DATA__
@@ garden-watering.yaml
<% my $valve_states = begin %>
% for my $entry (@$entries) {
  - platform: template
    name: "<%= $entry->{name} %> valve state"
    id: pot_<%= $entry->{number} %>_valve_state
% }
<% end %>

<% my $pot_sensor = begin %>
% for my $entry (@$entries) {
  - platform: cd74hc4067
    id: adc_pot_<%= $entry->{number} %>
    name: "<%= $entry->{name} %> soil value"
    number: <%= $entry->{sensor} %>
    sensor: ads1115_input
% }
<% end %>

<% my $pot_switch = begin %>
<% my $first = 1; %>
<% for my $entry (@$entries) {%>
  - platform: gpio
    name: "<%= $entry->{name} %> valve"
    id: pot_<%= $entry->{number} %>_valve
    restore_mode: ALWAYS_OFF
    <% if ($first) { %>
    interlock: &valve_interlock [<%= join ', ', map {"pot_".$_->{number}."_valve"} @$entries %>]
    <% $first = 0; } else { %>
    interlock: *valve_interlock
    <% } %>
    on_turn_on:
    - binary_sensor.template.publish:
        id: pot_<%= $entry->{number} %>_valve_state
        state: ON
    on_turn_off:
    - binary_sensor.template.publish:
        id: pot_<%= $entry->{number} %>_valve_state
        state: OFF
    pin:
      mcp23xxx: relay_gpio
      number: <%= $gpio_relay_map->{$entry->{switch}} %>
      mode:
        output: true
      inverted: true
<% } %>
<% end %>

<% my $enable_gpio = begin %>
<% for my $entry (@$entries) { %>
  - platform: gpio
    name: "<%= $entry->{name} %> enabled"
    id: pot_<%= $entry->{number} %>_enabled
    pin:
      mcp23xxx: status_gpio
      number: <%= $entry->{status} %>
      mode:
        output: false
        input: true
      inverted: true
<% } %>
<% end %>

### <%= $build_date %>

esphome:
  name: garden-watering

esp32:
  board: esp32dev
  framework:
    type: arduino

# Enable logging
logger:

# Enable Home Assistant API
api:

ota:
  password: "58e150f3586782f14b2a4d1daa8ff07c"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Garden-Watering Fallback Hotspot"
    password: "in2eFio6bwID"

captive_portal:

i2c:


mcp23008:
  - id: 'relay_gpio'
    address: 0x20
  - id: 'status_gpio'
    address: 0x21

ads1115:
  - address: 0x48
    id: ext_adc_1

cd74hc4067:
  - id: cd74hc4067_1
% for my $n (0..3) {
    pin_s<%= $n %>: <%= $analog_mux_pins->[$n] %>
% }

sensor:
  - platform: ads1115
    id: ads1115_input
    ads1115_id: ext_adc_1
    gain: 1.024
    multiplexer: "A0_GND"
    name: "raw adc value for multiplexer"
<%= $pot_sensor->() %>

switch:
  - platform: gpio
    name: "<%= $pump_mapping->{name} %>"
    id: pump_relay
    restore_mode: ALWAYS_OFF
    pin:
      mcp23xxx: relay_gpio
      number: <%= $gpio_relay_map->{$pump_mapping->{switch}} %>
      mode:
        output: true
      inverted: true
<%= $pot_switch->() %>

binary_sensor:
<%= $valve_states->() %>
<%= $enable_gpio->() %>

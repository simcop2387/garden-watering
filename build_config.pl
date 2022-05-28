#!/usr/bin/env perl

use strict;
use warnings;
use Path::Tiny;
use Mojo::Template;
use Data::Section::Simple qw/get_data_section/;
use Time::Piece;
use utf8;

my $out_path=path("dist");
$out_path->mkpath();

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
  {switch => 0, name => "Pot 16", sensor => "15", default_water => 10, max_water => 25, status => 14}, # not a real switch on there
);

for my $n (0..$#pot_mapping) {
  $pot_mapping[$n]{number} = $n
};

my $pump_mapping = 
  {switch => 0, name => "Pump Relay"};

my $analog_mux_pins = [qw/GPIO27 GPIO26 GPIO25 GPIO33/];

my $float_sensors = {low_pin => 'GPIO35', high_pin=>'GPIO34'};
my $water_sensor  = {pin => 'GPIO39', interval => '500ms', factor => 1.0, total_factor=> 1.0};

my %gpio_relay_map = (
 0 => 4,
 1 => 12,
 2 => 5,
 3 => 13,
 4 => 6,
 5 => 14,
 6 => 7,
 7 => 15,
 8 => 0,
 9 => 8,
 10 => 1,
 11 => 9,
 12 => 2,
 13 => 10,
 14 => 3,
 15 => 11
);

my $all = get_data_section;
my $mt = Mojo::Template->new();

my @files = qw/garden-watering.yaml/;

for my $file (@files) {
  $mt->name($file);
  my $build_date = localtime->datetime();
  my $out_file=$out_path->child($file);
  my $out = $mt->vars(1)->render($all->{$file}, {entries => \@pot_mapping, analog_mux_pins => $analog_mux_pins, gpio_relay_map => \%gpio_relay_map, pump_mapping => $pump_mapping, build_date=>$build_date, float_sensors => $float_sensors, water_sensor=>$water_sensor});
  $out_file->spew_utf8($out);
}

 
__END__
__DATA__
@@ garden-watering.yaml
### <%= $build_date %>

esphome:
  name: garden-watering

includes:
    - veml7700_custom_sensor.h
libraries:
    - "https://github.com/adafruit/Adafruit_VEML7700"

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

time:
  - platform: homeassistant
    timezone: "America/New_York"

# close enough for me, will use for reducing watering during the night
sun: 
  latitude: 35.22°
  longitude: 80.84°

mcp23017:
  - id: 'relay_gpio'
    address: 0x20
  - id: 'status_gpio'
    address: 0x21

ads1115:
  - address: 0x48
    id: ext_adc_1

cd74hc4067:
  - id: cd74hc4067_1
    delay: 15ms
% for my $n (0..3) {
    pin_s<%= $n %>: <%= $analog_mux_pins->[$n] %>
% }

sensor:
  - platform: custom
    lambda: |-
      auto veml7700 = new VEML7700CustomSensor();
      App.register_component(veml7700);
      return {veml7700, veml7700->lux_sensor, veml7700->white_sensor, veml7700->als_sensor};
      sensors:
        - name: "VEML7700 Light" # Required dummy sensor
        - name: "VEML770 Lux"
            unit_of_measurement: Lux
            accuracy_decimals: 0
        - name: "VEML770 White"
            unit_of_measurement: raw
            accuracy_decimals: 0
        - name: "VEML770 ALS"
            unit_of_measurement: raw
            accuracy_decimals: 0
  - platform: bme280
    temperature:
      name: "Garden Temperature"
    pressure:
      name: "Garden Pressure"
    humidity:
      name: "Garden Humidity"
    address: 0x77
    update_interval: 10s
  - platform: pulse_counter
    pin: <%= $water_sensor->{pin} %>
    update_interval: <%= $water_sensor->{interval} %>
    id: water_pulse
    name: "water pulse counter"
    unit_of_measurement: "mL/s"
    filters:
      - multiply: <%= $water_sensor->{factor} %>
    total:
      unit_of_measurement: "mL"
      name: "Water dispensed"
      filters:
        - multiply: <%= $water_sensor->{total_factor} %>
  - platform: ads1115
    id: ads1115_input
    ads1115_id: ext_adc_1
    gain: 4.096
    multiplexer: "A0_GND"
    name: "raw adc value for multiplexer a0"
  - platform: ads1115
    id: ads1115_input_1
    ads1115_id: ext_adc_1
    gain: 4.096
    multiplexer: "A1_GND"
    name: "raw adc value for multiplexer a1"
  - platform: ads1115
    id: ads1115_input_2
    ads1115_id: ext_adc_1
    gain: 4.096
    multiplexer: "A2_GND"
    name: "raw adc value for multiplexer a2"
  - platform: ads1115
    id: ads1115_input_3
    ads1115_id: ext_adc_1
    gain: 4.096
    multiplexer: "A3_GND"
    name: "raw adc value for multiplexer a3"

% for my $entry (@$entries) {
  - platform: cd74hc4067
    id: adc_pot_<%= $entry->{number} %>
    name: "<%= $entry->{name} %> soil value"
    number: <%= $entry->{sensor} %>
    sensor: ads1115_input
    update_interval: 30s
    force_update: true
    accuracy_decimals: 5
    unit_of_measurement: "V"
% }

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
% my $first = 1;
% for my $entry (@$entries) {
  - platform: gpio
    disabled_by_default: true
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
% }

binary_sensor:
  - platform: gpio
    filters:
      - delayed_on: 10ms
      - delayed_off: 10ms
    name: bucket level low
    pin:
      number: <%= $float_sensors->{low_pin} %>
      mode:
        input: true
        pullup: false

  - platform: gpio
    name: bucket level high
    filters:
      - delayed_on: 10ms
      - delayed_off: 10ms
    pin:
      number: <%= $float_sensors->{high_pin} %>
      mode:
        input: true
        pullup: false

% for my $entry (@$entries) {
  - platform: template
    name: "<%= $entry->{name} %> valve state"
    id: pot_<%= $entry->{number} %>_valve_state
% }

number:
% for my $entry (@$entries) {
  - platform: template
    name: "<%= $entry->{name} %> water needed"
    id: pot_<%= $entry->{number} %>_water_needed
    # in mL
    min_value: 0
    max_value: 100
    step: 1
    #    set_action:
    restore_value: false
    initial_value: 0
    disabled_by_default: true
  - platform: template
    name: "<%= $entry->{name} %> water received"
    id: pot_<%= $entry->{number} %>_water_received
    # in mL
    #    set_action:
    restore_value: false
    initial_value: 0
    disabled_by_default: true
    step: 1
  - platform: template
    name: "<%= $entry->{name} %> calibration max"
    id: pot_<%= $entry->{number} %>_cal_max
    restore_value: true
    initial_value: 2.5
    step: 0.0001
    min_value: 0.0
    max_value: 3.0
    optimistic: true
    disabled_by_default: true
  - platform: template
    name: "<%= $entry->{name} %> calibration min"
    id: pot_<%= $entry->{number} %>_cal_min
    step: 0.0001
    restore_value: true
    initial_value: 0.8
    min_value: 0.0
    max_value: 3.0
    optimistic: true
    disabled_by_default: true
  - platform: template
    name: "<%= $entry->{name} %> target threshold"
    id: pot_<%= $entry->{number} %>_target
    restore_value: true
    min_value: 0.0
    step: 0.001
    max_value: 3.0
    optimistic: true
    initial_value: 2.0 # good default?
    disabled_by_default: true
  - platform: template
    name: "<%= $entry->{name} %> alert threshold"
    id: pot_<%= $entry->{number} %>_water_received
    restore_value: true
    initial_value: 2.2 
    step: 0.001
    min_value: 0.0
    max_value: 3.0
    optimistic: true
    disabled_by_default: true
% }
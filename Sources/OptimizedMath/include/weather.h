#ifndef _WEATHER_H_
#define _WEATHER_H_

/// A somewhat simplified way of computing "feels like" temperatures that is relatively close over
/// a wide range of inputs. Returns values in Celsius.
extern float australianApparentTemperature(
    float tempC,
    float windMS,
    float relativeHumidity
);

/// The wind speed at which the slope of wind chill with relation to actual temperature is 1.
/// If the wind speed is lower than this, the value given by `windChill()` is not reliable.
#define MIN_WIND_CHILL_SPEED_MPH 0.4647751941289298

/// A power function approximation of wind chill. Only meant to be used for temperatures below 10C.
/// Returns values in Celsius.
extern float windChill(
    float tempC,
    double windKMH
);

/// Returns a cubic interpolation of the heat index based on the NWS table, in Fahrenheit. Only
/// meant to be used for temperatures above 80F, humidities below 100%, and negligible wind speeds.
extern float heatIndex(
    float tempF,
    float relativeHumidity
);

extern float tempCToF(float tempC);

extern double windMPHToKMH(double windMPH);

extern float windMPHToMS(float windMPH);

#endif

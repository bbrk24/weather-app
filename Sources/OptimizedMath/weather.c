#include <math.h>

// https://en.wikipedia.org/wiki/Apparent_temperature#Australian_apparent_temperature
static float vaporPressure(
    float tempC,
    float relativeHumidity
) {
    return relativeHumidity * 0.06105f * expf(17.27f * tempC / (237.7f + tempC));
}

float australianApparentTemperature(
    float tempC,
    float windMS,
    float relativeHumidity
) {
    float e = vaporPressure(tempC, relativeHumidity);
    return tempC + 0.33f * e - 0.7f * windMS - 4.0f;
}

// https://en.wikipedia.org/wiki/Wind_chill#North_American_and_United_Kingdom_wind_chill_index
float windChill(
    float tempC,
    double windKMH
) {
    double result =
        13.12
        + 0.6215 * tempC
        - 11.37 * pow(windKMH, 0.16)
        + 0.3965 * tempC * pow(windKMH, 0.16);
    return (float)result;
}

// https://en.wikipedia.org/wiki/Heat_index#Formula
float heatIndex(
    float tempF,
    float relativeHumidity
) {
    double result =
        16.923
        + 0.185212 * tempF
        + 5.37941 * relativeHumidity
        - 0.100254 * tempF * relativeHumidity
        + 9.41695e-3 * tempF * tempF
        + 7.28898e-3 * relativeHumidity * relativeHumidity
        + 3.45372e-4 * tempF * tempF * relativeHumidity
        - 8.14971e-4 * tempF * relativeHumidity * relativeHumidity
        + 1.02102e-5 * tempF * tempF * relativeHumidity * relativeHumidity
        - 3.8646e-5 * tempF * tempF * tempF
        + 2.91583e-5 * relativeHumidity * relativeHumidity * relativeHumidity
        + 1.42721e-6 * tempF * tempF * tempF * relativeHumidity
        + 1.97483e-7 * tempF * relativeHumidity * relativeHumidity * relativeHumidity
        - 2.18429e-8 * tempF * tempF * tempF * relativeHumidity * relativeHumidity
        + 8.43296e-10 * tempF * tempF * relativeHumidity * relativeHumidity * relativeHumidity
        - 4.81975e-11 * tempF * tempF * tempF * relativeHumidity * relativeHumidity * relativeHumidity;
    return (float)result;
}

// Unit conversions
float tempCToF(float tempC) {
    return 1.8f * tempC + 32.0f;
}

double windMPHToKMH(double windMPH) {
    return 1.609344 * windMPH;
}

float windMPHToMS(float windMPH) {
    return 0.44704f * windMPH;
}

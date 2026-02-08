import OptimizedMath
import Foundation

func feelsLikeTemperature(period: ForecastPeriod) -> Float {
    if
        period.temperature.value >= 26.666666,
        let humidity = period.relativeHumidity?.value
    {
        return heatIndex(tempCToF(period.temperature.value), humidity)
    } else {
        let windMPH = NSString(string: period.windSpeed).doubleValue
        
        if period.temperature.value <= 10.0 && windMPH > MIN_WIND_CHILL_SPEED_MPH {
            return tempCToF(windChill(period.temperature.value, windMPHToKMH(windMPH)))
        } else if let humidity = period.relativeHumidity?.value {
            return tempCToF(
                australianApparentTemperature(
                    period.temperature.value,
                    windMPHToMS(Float(windMPH)),
                    humidity
                )
            )
        }
    }
    
    return tempCToF(period.temperature.value)
}

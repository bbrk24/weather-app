import OptimizedMath
import Foundation

func feelsLikeTemperature(period: ForecastPeriod) -> Float {
    let windMPH = NSString(string: period.windSpeed).doubleValue

    if
        period.temperature.value >= 26.666666 && windMPH <= MIN_WIND_CHILL_SPEED_MPH,
        let humidity = period.relativeHumidity?.value
    {
        return heatIndex(tempCToF(period.temperature.value), humidity)
    } else if period.temperature.value <= 10.0 && windMPH > MIN_WIND_CHILL_SPEED_MPH {
        return tempCToF(windChill(period.temperature.value, windMPH * KILOMETERS_PER_MILE))
    } else if let humidity = period.relativeHumidity?.value {
        return tempCToF(
            australianApparentTemperature(
                period.temperature.value,
                windMPHToMS(Float(windMPH)),
                humidity
            )
        )
    }
    
    return tempCToF(period.temperature.value)
}

extension Sequence {
    consuming func unique<T: Hashable>(by keySelector: (Element) -> T) -> [Element] {
        var seenIds = Set<T>()
        var results = [Element]()

        for element in self {
            let id = keySelector(element)
            if seenIds.insert(id).inserted {
                results.append(element)
            }
        }

        return results
    }
}

private let gregorianCalendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}()

private let autumnEquinox = DateComponents(
    calendar: gregorianCalendarUTC,
    timeZone: .gmt,
    month: 9,
    day: 23,
    hour: 1,
    minute: 0
)

private let halfAYearTimeInterval: TimeInterval = 15778476

/// Determine whether the given time is day or night in the region.
///
/// If the sunrise or sunset time is nil, it is assumed to be a region in the arctic circle. The US
/// has no territorial claims south of the Tropic of Capricorn, and US Antarctic research bases are
/// not covered by the NWS.
func isTimeInDaylight(
    _ time: Date,
    astronomicalData: AstronomicalData,
    localCalendar: Calendar
) -> Bool {
    guard let sunrise = astronomicalData.sunrise,
          let sunset = astronomicalData.sunset else {
        let nextAutumnEquinox = gregorianCalendarUTC.nextDate(after: time, matching: autumnEquinox, matchingPolicy: .nextTime)!
        if nextAutumnEquinox.timeIntervalSince(time) > halfAYearTimeInterval {
            // Next Autumn equinox is more than half a year away, must be winter
            return false
        } else {
            // Next Autumn equinox is less than half a year away, must be summer
            return true
        }
    }

    let startOfSunriseDay = localCalendar.startOfDay(for: sunrise)
    let startOfSunsetDay = localCalendar.startOfDay(for: sunset)
    let startOfDay = localCalendar.startOfDay(for: time)

    let sunriseTimeOfDay = sunrise.timeIntervalSince(startOfSunriseDay)
    let sunsetTimeOfDay = sunset.timeIntervalSince(startOfSunsetDay)
    let timeOfDay = time.timeIntervalSince(startOfDay)

    let isBeforeSunrise = timeOfDay < sunriseTimeOfDay
    let isAfterSunset = timeOfDay > sunsetTimeOfDay

    return sunriseTimeOfDay < sunsetTimeOfDay
        ? !(isBeforeSunrise || isAfterSunset)
        : !(isBeforeSunrise && isAfterSunset)
}

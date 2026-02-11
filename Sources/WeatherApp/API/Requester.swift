import Alamofire
import Foundation

struct HttpResponse: Sendable {
    var code: Int
    var headers: HTTPHeaders
    var body: Data
}

protocol Requester: Sendable {
    func sendRequest(
        to url: any URLConvertible,
        headers: HTTPHeaders
    ) async throws(AFError) -> HttpResponse
}

struct Interceptor: RequestInterceptor {
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        debugPrint(error)

        if
            request.retryCount < 5,
            let response = request.response,
            response.statusCode == 429 || response.statusCode == 500
        {
            completion(.retryWithDelay(5.0))
        } else {
            completion(.doNotRetry)
        }
    }
}

final class RequesterImplementation: Requester {
    private let session = Session()

    private static let emptyData = Data()

    @MainActor
    init() {
        session.sessionConfiguration.headers.add(
            name: "User-Agent", 
            value: "Weather App/\(WeatherApp.version) (github.com/bbrk24/weather-app; bbrk24@gmail.com) Alamofire/\(AFInfo.version)"
        )
    }

    func sendRequest(
        to url: any URLConvertible,
        headers: HTTPHeaders
    ) async throws(AFError) -> HttpResponse {
        let request = session.request(
            url,
            method: .get,
            headers: headers
        )

        let response = await request.serializingData().response

        if let hur = response.response {
            return HttpResponse(code: hur.statusCode, headers: hur.headers, body: response.data ?? Self.emptyData)
        }  else if let error = response.error {
            throw error
        } else {
            preconditionFailure("Alamofire request produced neither response nor error")
        }
    }
}

struct HttpError: Error, CustomStringConvertible {
    var response: HttpResponse

    var description: String {
        "Unexpected status code \(response.code)"
    }
}

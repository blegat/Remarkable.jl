using Revise
using Remarkable
using HTTP
import JSON
client = RemarkableClient()
Remarkable.discover_storage(client)
list_items(client)
body = HTTP.request(
    client,
    "POST",
    "https://internal.cloud.remarkable.com/sync/v2/signed-urls/downloads";
    query = JSON.json(Dict(
        "http_method" => "GET",
        "relative_path" => "root",
    ))
)


module CoastApp
using Dash

const resources_path = realpath(joinpath( @__DIR__, "..", "deps"))
const version = "0.0.1"

include("coastapp.jl")

function __init__()
    DashBase.register_package(
        DashBase.ResourcePkg(
            "coast_app",
            resources_path,
            version = version,
            [
                DashBase.Resource(
    relative_package_path = "coast_app.min.js",
    external_url = "https://unpkg.com/coast_app@0.0.1/coast_app/coast_app.min.js",
    dynamic = nothing,
    async = nothing,
    type = :js
),
DashBase.Resource(
    relative_package_path = "coast_app.min.js.map",
    external_url = "https://unpkg.com/coast_app@0.0.1/coast_app/coast_app.min.js.map",
    dynamic = true,
    async = nothing,
    type = :js
)
            ]
        )

    )
end
end

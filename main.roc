app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.15.0/SlwdbJ-3GR7uBWQo6zlmYWNYOxnvo8r6YABXD-45UOw.tar.br" }

import pf.Stdout

Request : { path : Str, method : [GET, POST], body : [Json Str, NoContent] }

Handler m b resp : { method: m, body: b } -> resp
GenericHandler resp : Request -> Result resp [InvalidBody, InvalidMethod, InvalidPath]

RequestHandlerBuilder implements
    createHandler : val -> GenericHandler resp where val implements RequestHandlerBuilder

MethodFilter implements
    filterMethod : val -> (Request -> Result m [InvalidMethod, InvalidPath]) where val implements MethodFilter

BodyFilter implements
    filterBody : val -> (Request -> Result b [InvalidBody]) where val implements BodyFilter

GetFilter := Str implements [MethodFilter { filterMethod: filterGet }]

filterGet = \@GetFilter path -> 
    \req ->
        when req is
            { path: reqPath } if reqPath != path -> Err InvalidPath
            { method: GET } -> Ok GET
            _ -> Err InvalidMethod

PostFilter := Str implements [MethodFilter { filterMethod: filterPost }]

filterPost = \@PostFilter path -> 
    \req ->
        when req is
            { path: reqPath } if reqPath != path -> Err InvalidPath
            { method: POST } -> Ok POST
            _ -> Err InvalidMethod

JsonFilter := {} implements [BodyFilter { filterBody: filterJson }]

filterJson = \@JsonFilter {} -> 
    \req ->
        when req is
            { body: Json c } -> Json c |> Ok
            _ -> Err InvalidBody

NoContentFilter := {} implements [BodyFilter { filterBody: filterNoContent }]
filterNoContent = \@NoContentFilter {} -> 
    \req ->
        when req is
            { body: NoContent } -> Ok NoContent
            _ -> Err InvalidBody

Route mf bf m b resp := (
        mf,
        bf,
        Handler m b resp
    ) where bf implements BodyFilter, mf implements MethodFilter
    implements [RequestHandlerBuilder { createHandler: createRouteHandler }]

createRouteHandler = \@Route (methodFilter, bodyFilter, handler) ->
    filterBodyT = filterBody bodyFilter
    filterMethodT = filterMethod methodFilter
    \req ->
        b = filterBodyT? req
        m = filterMethodT? req
        handler {method: m, body: b}
        |> Ok

get = \path ->
    @GetFilter path

post = \path ->
    @PostFilter path

json = @JsonFilter {}

noContent = @NoContentFilter {}


receiving = \methodFilter, bodyFilter ->
    (methodFilter, bodyFilter)

using : (mf, bf), Handler m b resp -> GenericHandler resp where mf implements MethodFilter, bf implements BodyFilter
using = \(mf, mb), handler ->
    createHandler (@Route (mf, mb, handler))

getTodosRoute : GenericHandler [Ok Str, BadRequest]
getTodosRoute =
    get "/todos"
    |> receiving noContent
    |> using (\{method: GET, body: NoContent} -> Ok "get received")

postTodosRoute : GenericHandler [Ok Str, BadRequest]
postTodosRoute =
    post "/todos"
    |> receiving json
    |> using (\{method: POST, body: Json c} -> Ok "post received: $(c)")

getRequest = { path: "/todos", method: GET, body: NoContent }
postRequest = { path: "/todos", method: POST, body: Json "body" }

routeRequest = \handlers -> 
    \req ->
        handlers
        |> List.map (\handler -> handler req)

main =
    handleRequest = routeRequest [getTodosRoute, postTodosRoute]

    handleRequest getRequest
    |> Inspect.toStr
    |> Stdout.line!

    handleRequest postRequest
    |> Inspect.toStr
    |> Stdout.line! 

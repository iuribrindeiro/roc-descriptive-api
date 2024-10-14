My goal with this repo is to make some experiments with roc and how far I can get with its incredible type system.

## The problem Roc might help me solve: ##
One of the things that always annoyed me when developing REST apis was that I always had to manually document what every endpoint receives and returns.
Of course, there are some helpful frameworks and libraries like [OpenAPI](https://github.com/microsoft/OpenAPI.NET) for .NET, for example.
The problem is that these libraries can't capture exactly what my routes are returning in every case.
I believe this is mostly due to the lack of a closed-type hierarchy.

For example, if I return a response of `Result.Ok(todo)` in a .NET application, it will be smart enough to know it returns an `Ok<Todo>`.
But if I make some code changes and return something like `NotFound` now I need to update the documentation to declare that this particular endpoint now returns a 404.
Of course, .NET now has this _fancy_ [result type](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-8.0&tabs=visual-studio%2Cminimal-apis#multiple-response-types) that would make this a bit easier.
But still, I can't say that I return something, and in practice not return it.

What if I could just return the thing and the API would "automagically" update accordingly?

Imagine that I just added this if statement: `if (todo == null) return NotFound() else return Ok(todo)` and now the API docs (open API/Swagger in this case) are updated with the possible 404 response.
Or even cooler than that: `return NotFound("Sorry, no todo here")` and the documentation is automatically updated to `Ok<Todo> | NotFound<string>`.

## One of Roc's main advantages: ##
When learning Roc you'll soon realize how smart the compiler is and how it can infer stuff just by how you are using values.

For example:
```roc
  someFunction = \{firstName, lastName} ->
    ...
    nameToU8 = \name ->
      Str.toU8 name
    ...
    nameToU8 firstName
  ...
```

In roc, I wouldn't need to declare the params for any of these functions.
Str.toU8 has the following signature: `Str -> Result U8 [InvalidNumStr]`, hence, whatever I'm giving to it **needs** to be a String (or Str).
If I give anything that I declared somewhere else as something that is not a String, the compiler will let me know and won't let the code run.

So, since I didn't declare the `name` param type, Roc knows that it should be a String, because I'm passing it to `Str.toU8`.
The same goes to `someFunction = \{firstName, lastName}`. Since I didn't declare the argument of these function and I am [destructing](https://www.roc-lang.org/tutorial#record-destructuring) it as a record, 
Roc knows that this is a record with at least 2 fields, `firstName` and `lastName`.

Ok, but the reason why I think Roc might actually be able to do what I want is that it can also [accumulate](https://www.roc-lang.org/tutorial#accumulating-tag-types) [tag unions](https://www.roc-lang.org/tutorial#tag-union-types).

For example, if I have a function like this:

```roc
  colorToTag = \color ->
    when color is
      "red" -> Red
      "green" -> Green
      _ -> AnyOtherColor
```

Roc will automatically define the return type of this function as `[Red, Green, AnyOtherColor]`.
Removing any of these branches will result in a different function signature.
Also, adding a new "case" to this with a new unique tag will also change the function signature to add the new tag.

This is exactly what I need to make the self-descriptive API!!!

## Progress so far: ##
So far, I could only create some sort of generic code to handle any type of request based on HTTP method or body content-type.
I wanted to do this in a way that I could let the compiler help me to use only the content type that I was describing my api to receive.
Saying that I was receiving `application/json` and then reading `application/xml` from the "request context" was something that I wanted to be impossible.

This is the syntax that I came up with so far:

```roc
post "/todos"
    |> receiving json
    |> using (\{method: POST, body: Json c} -> Ok "post received: $(c)")
```

If you try to pattern match on the `body` property for anything that is not a `Json c`, you'll get a compiler error.
Changing the second line to something like `receiving noContent` will also guide you to change the `body` type to `body: NoContent`.

## Next steps: ##

Next, I would like to implement a new [ability](https://www.roc-lang.org/abilities) to describe the types. 
Later, also describe the individual `handler` types for each route, so I can get its return type and create particular "route descriptions" for every route.

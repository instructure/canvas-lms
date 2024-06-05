
## `useZodSearchParams`:

Uses `zod` to parse URL path params and search params
### Parsing Query parameters:
Given a URL like:
```
/url?a=foo&b=bar&a=baz
```

You can define a set of string schemas to parse them like:

```
const searchParams = useZodSearchParams({
  a: z.array(z.string()),
  b: z.string(),
  c: z.string().optional()
});
```

The search parameters are parsed using `safeParse`, and thus `useZodSearchParams` returns a `ParamsParseResult`, which is either successful with a value, or unsuccessful with a list of errors. Validate the `success` attribute to have typescript narrow the definition:
```
if(searchParams.success){
  searchParams.value // accessible here
} else {
  searchParams.errors // errors accessible if unsuccessful
}
```

The top-level argument to `useZodSearchParams` is not a schema itself, it is a record of strings (parameter names) to schemas with an input type of `string` or `Array<string>`. Since `useZodParams` is based on `URLSearchParams`, every value comes to it as a string, and thus hands each string off to the `zod` schemas.

You can parse the string to any type. Some common examples are `enum`s, `bool`s, and `Date`s:
```
const searchParams = useZodSearchParams({
  userId: z.string().brand('UserId'),
  sort: z.enum(['name', 'age']).default('name'),
  from: z.string().pipe(z.coerce.date()).optional()
});
```

Typescript will infer the parsed parameter types from the input schemas:
```
if(searchParams.success) {
  searchParams.value.userId // UserId
  searchParams.value.sort   // 'name' | 'age'
  searchParams.value.from   // Date | undefined 
}
```

### Errors
Errors come with a human readable message, which is useful while debugging. You can format a list of error messages with the `formatSearchParamErrorMessage` helper:
```
if(searchParams.success) {}
else {
  formatSearchParamErrorMessage(searchParams.errors)
}
```

### Caveats/Tradeoffs

There is no typed `setSearchParams`. Since `zod` schemas are uni-directional (They can only parse from `string => A`, and cannot transform the other way `A => string`), There is no way to provide a `setSearchParams` that takes the input types as is.

Arrays & Optionals are checked by name, and thus `useZodSearchParams` is not parametrically polymorphic. Thus, you cannot create a custom schema that generalizes over `Array`s, you must use `z.array`.

## `useZodParams`:

The `useZodParams` is much like `useZodSearchParams`, except it is based on react router's `useParams` (based on their URL template parameters). Another difference is that `useZodParams` only works with zod schemas that take in a string (vs an array of strings, or optional strings).

### Parsing URL parameters:
Given a react router URL template like:
```
/courses/:courseId/assignments/:assignmentId
```

You can define a set of string schemas to parse them like:

```
const params = useZodParams({
  a: z.string(),
  b: z.enum(['foo', 'bar']),
})
```

The search parameters are parsed using `safeParse`, and thus `useZodParams` returns a `ParamsParseResult`, which is either successful with a value, or unsuccessful with a list of errors. Validate the `success` attribute to have typescript narrow the definition:
```
if(searchParams.success){
  searchParams.value.a // accessible here
} else {
  searchParams.errors // errors accessible if unsuccessful
}
```

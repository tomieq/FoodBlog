# Build Image
```
docker build -t tomieq/food_blog:1.0 .
```

# Run
## Debug server
```
docker run --rm -p 8084:8080 -v food_volume:/app/volume --env auth_token={some_token_here} --env admin_pass={some_password_here} tomieq/food_blog:1.0
```
## Prod server
```
docker run -d --restart always -p 8084:8080 -v food_volume:/app/volume --env auth_token={some_token_here} --env admin_pass={some_password_here} tomieq/food_blog:1.0
```
# Local run
```
export admin_pass={some_password_here}
export auth_token={some_token_here}
swift build && .build/debug/FoodBlog
```

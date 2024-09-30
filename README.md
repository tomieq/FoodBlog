# Build Image
```
docker build -t tomieq/food_blog:1.0 .
```

# Run
```
docker run --rm -p 8080:8080 -v food_volume:/volume: tomieq/food_blog:1.0
```

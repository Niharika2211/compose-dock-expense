```bash
# Create Docker network
docker network create expense
```

```bash
# Build MySQL image
docker build -t mysql:v1 .
```

```bash
# Build Backend image
docker build -t backend:v1 .
```

```bash
# Build Frontend image
docker build -t frontend:v1 .
```

```bash
# Run Debug Utility container
docker run --rm -dit --name debug --network expense siva9666/debug-utility:v1
```

```bash
# Run MySQL container
docker run --rm -itd --name mysql \
 -e MYSQL_ROOT_PASSWORD=ExpenseApp@1 \
 -e MYSQL_USER=expense \
 -e MYSQL_PASSWORD=ExpenseApp@1 \
 -e MYSQL_DATABASE=transactions \
 --network expense mysql:v1
```

```bash
# Run Backend container
docker run --rm -itd --name backend \
 -e DB_HOST=mysql \
 -e DB_USER=expense \
 -e DB_PWD=ExpenseApp@1 \
 -e DB_DATABASE=transactions \
 --network expense backend:v1
```

```bash
# Run Frontend container
docker run --rm -itd --name frontend -p 80:80 --network expense frontend:v1
```

```bash
# View container logs
docker logs -f <container-name>
```

```bash
# Inspect Docker network
docker inspect network expense
```
```bash
docker network create expense
```

```bash
docker build -t mysql:v1 .
```

```bash
docker build -t backend:v1 .
```

```bash
docker build -t frontend:v1 .
```

```bash
docker run --rm -dit --name debug --network expense siva9666/debug-utility:v1
```

```bash
docker run --rm -itd --name mysql \
 -e MYSQL_ROOT_PASSWORD=ExpenseApp@1 \
 -e MYSQL_USER=expense \
 -e MYSQL_PASSWORD=ExpenseApp@1 \
 -e MYSQL_DATABASE=transactions \
 --network expense mysql:v1
```

```bash
docker run --rm -itd --name backend \
 -e DB_HOST=mysql \
 -e DB_USER=expense \
 -e DB_PWD=ExpenseApp@1 \
 -e DB_DATABASE=transactions \
 --network expense backend:v1
```

```bash
docker run --rm -itd --name frontend -p 80:80 --network expense frontend:v1
```

```bash
docker logs -f <container-name>
```

```bash
docker inspect network expense
```

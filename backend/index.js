// const transactionService = require('./TransactionService');
// const express = require('express');
// const bodyParser = require('body-parser');
// const cors = require('cors');
// const moment = require('moment');

// const app = express();
// const port = 8080;

// // Middleware
// app.use(bodyParser.urlencoded({ extended: true }));
// app.use(bodyParser.json());

// // CORS Configuration
// // app.use(cors({
// //     origin: 'http://expense-s3-cors.s3-website.ap-south-1.amazonaws.com',
// //     methods: ['GET', 'POST', 'PUT', 'DELETE'],
// //     allowedHeaders: ['Content-Type', 'Authorization'],
// //     credentials: true
// // }));

// app.use(cors());

// // Health Check
// app.get('/health', (req, res) => {
//     res.json("This is the health check");
// });

// // Add Transaction
// app.post('/transaction', (req, res) => {
//     try {
//         const timestamp = moment().unix();
//         console.log(`{ "timestamp": ${timestamp}, "msg": "Adding Expense", "amount": ${req.body.amount}, "Description": "${req.body.desc}" }`);

//         const success = transactionService.addTransaction(req.body.amount, req.body.desc);

//         if (success === 200) {
//             res.json({ message: 'Transaction added successfully' });
//         } else {
//             res.status(500).json({ message: 'Failed to add transaction' });
//         }
//     } catch (err) {
//         res.status(500).json({ message: 'Something went wrong', error: err.message });
//     }
// });

// // Get All Transactions
// app.get('/transaction', (req, res) => {
//     try {
//         transactionService.getAllTransactions((results) => {
//             const transactionList = results.map(row => ({
//                 id: row.id,
//                 amount: row.amount,
//                 description: row.description
//             }));

//             const timestamp = moment().unix();
//             console.log(`{ "timestamp": ${timestamp}, "msg": "Getting All Expenses" }`);
//             console.log(`{ "expenses": ${JSON.stringify(transactionList)} }`);

//             res.status(200).json({ result: transactionList });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Could not get all transactions", error: err.message });
//     }
// });

// // Delete All Transactions
// app.delete('/transaction', (req, res) => {
//     try {
//         transactionService.deleteAllTransactions(() => {
//             const timestamp = moment().unix();
//             console.log(`{ "timestamp": ${timestamp}, "msg": "Deleted All Expenses" }`);

//             res.status(200).json({ message: "All transactions deleted successfully" });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Deleting all transactions failed", error: err.message });
//     }
// });

// // Delete One Transaction
// app.delete('/transaction/:id', (req, res) => {
//     try {
//         const { id } = req.params;

//         transactionService.deleteTransactionById(id, () => {
//             res.status(200).json({ message: `Transaction with ID ${id} deleted successfully` });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Error deleting transaction", error: err.message });
//     }
// });

// // Get Single Transaction
// app.get('/transaction/:id', (req, res) => {
//     try {
//         const { id } = req.params;

//         transactionService.findTransactionById(id, (result) => {
//             if (result.length > 0) {
//                 const transaction = {
//                     id: result[0].id,
//                     amount: result[0].amount,
//                     desc: result[0].desc
//                 };

//                 res.status(200).json(transaction);
//             } else {
//                 res.status(404).json({ message: "Transaction not found" });
//             }
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Error retrieving transaction", error: err.message });
//     }
// });

// // Start Server
// app.listen(port, () => {
//     const timestamp = moment().unix();
//     console.log(`{ "timestamp": ${timestamp}, "msg": "App Started on Port ${port}" }`);
// });


// const transactionService = require('./TransactionService');
// const express = require('express');
// const bodyParser = require('body-parser');
// const cors = require('cors');
// const moment = require('moment');
// const promClient = require('prom-client'); // Add prom-client

// const app = express();
// const port = 8080;

// // Enable metrics collection
// promClient.collectDefaultMetrics(); // Collects default metrics (CPU, memory, etc.)

// // Custom metrics
// const httpRequestCounter = new promClient.Counter({
//     name: 'http_requests_total',
//     help: 'Total number of HTTP requests',
//     labelNames: ['method', 'route', 'status'],
// });

// const transactionAddedCounter = new promClient.Counter({
//     name: 'transactions_added_total',
//     help: 'Total number of transactions added',
//     labelNames: ['status'],
// });

// // Middleware
// app.use(bodyParser.urlencoded({ extended: true }));
// app.use(bodyParser.json());
// app.use(cors());

// // Middleware to count HTTP requests
// app.use((req, res, next) => {
//     res.on('finish', () => {
//         httpRequestCounter.inc({
//             method: req.method,
//             route: req.path,
//             status: res.statusCode,
//         });
//     });
//     next();
// });

// // Health Check
// app.get('/health', (req, res) => {
//     res.json("This is the health check");
// });

// // Metrics Endpoint
// app.get('/metrics', async (req, res) => {
//     res.set('Content-Type', promClient.register.contentType);
//     res.end(await promClient.register.metrics());
// });

// // Add Transaction
// app.post('/transaction', (req, res) => {
//     try {
//         const timestamp = moment().unix();
//         console.log(`{ "timestamp": ${timestamp}, "msg": "Adding Expense", "amount": ${req.body.amount}, "Description": "${req.body.desc}" }`);

//         const success = transactionService.addTransaction(req.body.amount, req.body.desc);

//         if (success === 200) {
//             transactionAddedCounter.inc({ status: 'success' });
//             res.json({ message: 'Transaction added successfully' });
//         } else {
//             transactionAddedCounter.inc({ status: 'failed' });
//             res.status(500).json({ message: 'Failed to add transaction' });
//         }
//     } catch (err) {
//         transactionAddedCounter.inc({ status: 'error' });
//         res.status(500).json({ message: 'Something went wrong', error: err.message });
//     }
// });

// // Get All Transactions
// app.get('/transaction', (req, res) => {
//     try {
//         transactionService.getAllTransactions((results) => {
//             const transactionList = results.map(row => ({
//                 id: row.id,
//                 amount: row.amount,
//                 description: row.description
//             }));

//             const timestamp = moment().unix();
//             console.log(`{ "timestamp": ${timestamp}, "msg": "Getting All Expenses" }`);
//             console.log(`{ "expenses": ${JSON.stringify(transactionList)} }`);

//             res.status(200).json({ result: transactionList });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Could not get all transactions", error: err.message });
//     }
// });

// // Delete All Transactions
// app.delete('/transaction', (req, res) => {
//     try {
//         transactionService.deleteAllTransactions(() => {
//             const timestamp = moment().unix();
//             console.log(`{ "timestamp": ${timestamp}, "msg": "Deleted All Expenses" }`);

//             res.status(200).json({ message: "All transactions deleted successfully" });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Deleting all transactions failed", error: err.message });
//     }
// });

// // Delete One Transaction
// app.delete('/transaction/:id', (req, res) => {
//     try {
//         const { id } = req.params;

//         transactionService.deleteTransactionById(id, () => {
//             res.status(200).json({ message: `Transaction with ID ${id} deleted successfully` });
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Error deleting transaction", error: err.message });
//     }
// });

// // Get Single Transaction
// app.get('/transaction/:id', (req, res) => {
//     try {
//         const { id } = req.params;

//         transactionService.findTransactionById(id, (result) => {
//             if (result.length > 0) {
//                 const transaction = {
//                     id: result[0].id,
//                     amount: result[0].amount,
//                     desc: result[0].desc
//                 };

//                 res.status(200).json(transaction);
//             } else {
//                 res.status(404).json({ message: "Transaction not found" });
//             }
//         });
//     } catch (err) {
//         res.status(500).json({ message: "Error retrieving transaction", error: err.message });
//     }
// });

// // Start Server
// app.listen(port, () => {
//     const timestamp = moment().unix();
//     console.log(`{ "timestamp": ${timestamp}, "msg": "App Started on Port ${port}" }`);
// });


// const transactionService = require('./TransactionService');
// const express = require('express');
// const bodyParser = require('body-parser');
// const cors = require('cors');
// const moment = require('moment');
// const promClient = require('prom-client');
// const winston = require('winston'); // Logger
// const { initTracer } = require('jaeger-client'); // OpenTracing
// const opentracing = require('opentracing'); // OpenTracing core
// const expressOpentracing = require('express-opentracing').default; // Middleware for tracing
// const responseTime = require('response-time'); // Latency middleware

// const app = express();
// const port = 8080;

// // Prometheus Metrics
// promClient.collectDefaultMetrics();
// const httpRequestCounter = new promClient.Counter({
//     name: 'http_requests_total',
//     help: 'Total number of HTTP requests',
//     labelNames: ['method', 'route', 'status'],
// });
// const transactionAddedCounter = new promClient.Counter({
//     name: 'transactions_added_total',
//     help: 'Total number of transactions added',
//     labelNames: ['status'],
// });
// const httpRequestLatency = new promClient.Histogram({
//     name: 'http_request_latency_seconds',
//     help: 'HTTP request latency in seconds',
//     labelNames: ['method', 'route', 'status'],
//     buckets: [0.1, 0.5, 1, 2, 5], // Adjust buckets as needed
// });

// // Logger Setup (Winston)
// const logger = winston.createLogger({
//     level: 'info',
//     format: winston.format.combine(
//         winston.format.timestamp(),
//         winston.format.json()
//     ),
//     transports: [
//         new winston.transports.Console(),
//         new winston.transports.File({ filename: 'app.log' }) // Logs to file
//     ],
// });

// // Jaeger OpenTracing Setup
// const jaegerConfig = {
//     serviceName: 'expense-backend',
//     sampler: { type: 'const', param: 1 }, // Sample all requests
//     reporter: { collectorEndpoint: 'http://jaeger:14268/api/traces' }, // Jaeger collector
// };
// const jaegerOptions = { logger: logger };
// const tracer = initTracer(jaegerConfig, jaegerOptions);

// // Middleware
// app.use(bodyParser.urlencoded({ extended: true }));
// app.use(bodyParser.json());
// app.use(cors());
// app.use(expressOpentracing({ tracer })); // Tracing middleware
// app.use(responseTime((req, res, time) => {
//     // Record latency in seconds
//     httpRequestLatency.observe({
//         method: req.method,
//         route: req.path,
//         status: res.statusCode,
//     }, time / 1000); // Convert ms to seconds
// }));
// app.use((req, res, next) => {
//     res.on('finish', () => {
//         httpRequestCounter.inc({
//             method: req.method,
//             route: req.path,
//             status: res.statusCode,
//         });
//         logger.info({
//             method: req.method,
//             path: req.path,
//             status: res.statusCode,
//             latency_ms: res.get('X-Response-Time'), // From response-time
//         });
//     });
//     next();
// });

// // Health Check
// app.get('/health', (req, res) => {
//     res.json("This is the health check");
// });

// // Metrics Endpoint
// app.get('/metrics', async (req, res) => {
//     res.set('Content-Type', promClient.register.contentType);
//     res.end(await promClient.register.metrics());
// });

// // Add Transaction
// app.post('/transaction', (req, res) => {
//     const span = tracer.startSpan('add_transaction'); // Start tracing span
//     try {
//         const timestamp = moment().unix();
//         logger.info({
//             timestamp,
//             msg: 'Adding Expense',
//             amount: req.body.amount,
//             description: req.body.desc,
//         });

//         const success = transactionService.addTransaction(req.body.amount, req.body.desc);
//         span.setTag('amount', req.body.amount);
//         span.setTag('description', req.body.desc);

//         if (success === 200) {
//             transactionAddedCounter.inc({ status: 'success' });
//             span.setTag('success', true);
//             res.json({ message: 'Transaction added successfully' });
//         } else {
//             transactionAddedCounter.inc({ status: 'failed' });
//             span.setTag('success', false);
//             res.status(500).json({ message: 'Failed to add transaction' });
//         }
//     } catch (err) {
//         transactionAddedCounter.inc({ status: 'error' });
//         span.log({ event: 'error', message: err.message });
//         span.setTag('error', true);
//         res.status(500).json({ message: 'Something went wrong', error: err.message });
//     } finally {
//         span.finish(); // End tracing span
//     }
// });

// // Get All Transactions
// app.get('/transaction', (req, res) => {
//     const span = tracer.startSpan('get_all_transactions');
//     try {
//         transactionService.getAllTransactions((results) => {
//             const transactionList = results.map(row => ({
//                 id: row.id,
//                 amount: row.amount,
//                 description: row.description
//             }));

//             const timestamp = moment().unix();
//             logger.info({ timestamp, msg: 'Getting All Expenses', expenses: transactionList });
//             span.setTag('transaction_count', transactionList.length);

//             res.status(200).json({ result: transactionList });
//             span.finish();
//         });
//     } catch (err) {
//         span.log({ event: 'error', message: err.message });
//         span.setTag('error', true);
//         res.status(500).json({ message: 'Could not get all transactions', error: err.message });
//         span.finish();
//     }
// });

// // Delete All Transactions
// app.delete('/transaction', (req, res) => {
//     const span = tracer.startSpan('delete_all_transactions');
//     try {
//         transactionService.deleteAllTransactions(() => {
//             const timestamp = moment().unix();
//             logger.info({ timestamp, msg: 'Deleted All Expenses' });
//             span.setTag('success', true);

//             res.status(200).json({ message: 'All transactions deleted successfully' });
//             span.finish();
//         });
//     } catch (err) {
//         span.log({ event: 'error', message: err.message });
//         span.setTag('error', true);
//         res.status(500).json({ message: 'Deleting all transactions failed', error: err.message });
//         span.finish();
//     }
// });

// // Delete One Transaction
// app.delete('/transaction/:id', (req, res) => {
//     const span = tracer.startSpan('delete_transaction_by_id');
//     try {
//         const { id } = req.params;
//         span.setTag('transaction_id', id);

//         transactionService.deleteTransactionById(id, () => {
//             logger.info({ msg: `Deleted transaction with ID ${id}` });
//             span.setTag('success', true);

//             res.status(200).json({ message: `Transaction with ID ${id} deleted successfully` });
//             span.finish();
//         });
//     } catch (err) {
//         span.log({ event: 'error', message: err.message });
//         span.setTag('error', true);
//         res.status(500).json({ message: 'Error deleting transaction', error: err.message });
//         span.finish();
//     }
// });

// // Get Single Transaction
// app.get('/transaction/:id', (req, res) => {
//     const span = tracer.startSpan('get_transaction_by_id');
//     try {
//         const { id } = req.params;
//         span.setTag('transaction_id', id);

//         transactionService.findTransactionById(id, (result) => {
//             if (result.length > 0) {
//                 const transaction = {
//                     id: result[0].id,
//                     amount: result[0].amount,
//                     desc: result[0].desc
//                 };
//                 logger.info({ msg: `Retrieved transaction with ID ${id}`, transaction });
//                 span.setTag('found', true);

//                 res.status(200).json(transaction);
//             } else {
//                 span.setTag('found', false);
//                 res.status(404).json({ message: 'Transaction not found' });
//             }
//             span.finish();
//         });
//     } catch (err) {
//         span.log({ event: 'error', message: err.message });
//         span.setTag('error', true);
//         res.status(500).json({ message: 'Error retrieving transaction', error: err.message });
//         span.finish();
//     }
// });

// // Start Server
// app.listen(port, () => {
//     const timestamp = moment().unix();
//     logger.info({ timestamp, msg: `App Started on Port ${port}` });
// });


const transactionService = require('./TransactionService');
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const moment = require('moment');
const promClient = require('prom-client');
const winston = require('winston');
const { initTracer, opentracing } = require('jaeger-client');
const expressOpentracing = require('express-opentracing').default;
const responseTime = require('response-time');

const app = express();
const port = 8080;

// Prometheus Metrics
promClient.collectDefaultMetrics();
const httpRequestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status'],
});
const transactionAddedCounter = new promClient.Counter({
    name: 'transactions_added_total',
    help: 'Total number of transactions added',
    labelNames: ['status'],
});
const httpRequestLatency = new promClient.Histogram({
    name: 'http_request_latency_seconds',
    help: 'HTTP request latency in seconds',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.1, 0.5, 1, 2, 5],
});

// Logger Setup (Winston)
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'app.log' })
    ],
});

// Jaeger OpenTracing Setup
const jaegerConfig = {
    serviceName: 'expense-backend',
    sampler: { type: 'const', param: 1 },
    reporter: { collectorEndpoint: 'http://jaeger:14268/api/traces' },
};
const jaegerOptions = { logger: logger };
const tracer = initTracer(jaegerConfig, jaegerOptions);

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());
app.use(responseTime((req, res, time) => {
    httpRequestLatency.observe({
        method: req.method,
        route: req.path,
        status: res.statusCode,
    }, time / 1000);
}));
app.use((req, res, next) => {
    res.on('finish', () => {
        httpRequestCounter.inc({
            method: req.method,
            route: req.path,
            status: res.statusCode,
        });
        logger.info({
            method: req.method,
            path: req.path,
            status: res.statusCode,
            latency_ms: res.get('X-Response-Time'),
        });
    });
    next();
});

// Move express-opentracing middleware to specific routes if needed, avoiding global auto-finish

// Health Check
app.get('/health', (req, res) => {
    const span = tracer.startSpan('health_check');
    res.json("This is the health check");
    span.finish();
});

// Metrics Endpoint
app.get('/metrics', async (req, res) => {
    const span = tracer.startSpan('get_metrics');
    try {
        res.set('Content-Type', promClient.register.contentType);
        const metrics = await promClient.register.metrics();
        res.end(metrics);
    } catch (err) {
        logger.error({ message: 'Error serving metrics', error: err.message });
        res.status(500).end('Error serving metrics');
    } finally {
        span.finish();
    }
});

// Add Transaction
app.post('/transaction', expressOpentracing({ tracer }), (req, res) => {
    const span = req.tracer.startSpan('add_transaction', { childOf: req.span });
    try {
        const timestamp = moment().unix();
        logger.info({
            timestamp,
            msg: 'Adding Expense',
            amount: req.body.amount,
            description: req.body.desc,
        });

        const success = transactionService.addTransaction(req.body.amount, req.body.desc);
        span.setTag('amount', req.body.amount);
        span.setTag('description', req.body.desc);

        if (success === 200) {
            transactionAddedCounter.inc({ status: 'success' });
            span.setTag('success', true);
            res.json({ message: 'Transaction added successfully' });
        } else {
            transactionAddedCounter.inc({ status: 'failed' });
            span.setTag('success', false);
            res.status(500).json({ message: 'Failed to add transaction' });
        }
    } catch (err) {
        transactionAddedCounter.inc({ status: 'error' });
        span.log({ event: 'error', message: err.message });
        span.setTag('error', true);
        res.status(500).json({ message: 'Something went wrong', error: err.message });
    } finally {
        span.finish();
    }
});

// Get All Transactions (Handle async callback)
app.get('/transaction', expressOpentracing({ tracer }), (req, res) => {
    const span = req.tracer.startSpan('get_all_transactions', { childOf: req.span });
    transactionService.getAllTransactions((results) => {
        try {
            const transactionList = results.map(row => ({
                id: row.id,
                amount: row.amount,
                description: row.description
            }));

            const timestamp = moment().unix();
            logger.info({ timestamp, msg: 'Getting All Expenses', expenses: transactionList });
            span.setTag('transaction_count', transactionList.length);

            res.status(200).json({ result: transactionList });
        } catch (err) {
            span.log({ event: 'error', message: err.message });
            span.setTag('error', true);
            res.status(500).json({ message: 'Could not get all transactions', error: err.message });
        } finally {
            span.finish();
        }
    });
});

// Delete All Transactions
app.delete('/transaction', expressOpentracing({ tracer }), (req, res) => {
    const span = req.tracer.startSpan('delete_all_transactions', { childOf: req.span });
    transactionService.deleteAllTransactions(() => {
        try {
            const timestamp = moment().unix();
            logger.info({ timestamp, msg: 'Deleted All Expenses' });
            span.setTag('success', true);

            res.status(200).json({ message: 'All transactions deleted successfully' });
        } catch (err) {
            span.log({ event: 'error', message: err.message });
            span.setTag('error', true);
            res.status(500).json({ message: 'Deleting all transactions failed', error: err.message });
        } finally {
            span.finish();
        }
    });
});

// Delete One Transaction
app.delete('/transaction/:id', expressOpentracing({ tracer }), (req, res) => {
    const span = req.tracer.startSpan('delete_transaction_by_id', { childOf: req.span });
    const { id } = req.params;
    span.setTag('transaction_id', id);

    transactionService.deleteTransactionById(id, () => {
        try {
            logger.info({ msg: `Deleted transaction with ID ${id}` });
            span.setTag('success', true);

            res.status(200).json({ message: `Transaction with ID ${id} deleted successfully` });
        } catch (err) {
            span.log({ event: 'error', message: err.message });
            span.setTag('error', true);
            res.status(500).json({ message: 'Error deleting transaction', error: err.message });
        } finally {
            span.finish();
        }
    });
});

// Get Single Transaction
app.get('/transaction/:id', expressOpentracing({ tracer }), (req, res) => {
    const span = req.tracer.startSpan('get_transaction_by_id', { childOf: req.span });
    const { id } = req.params;
    span.setTag('transaction_id', id);

    transactionService.findTransactionById(id, (result) => {
        try {
            if (result.length > 0) {
                const transaction = {
                    id: result[0].id,
                    amount: result[0].amount,
                    desc: result[0].desc
                };
                logger.info({ msg: `Retrieved transaction with ID ${id}`, transaction });
                span.setTag('found', true);

                res.status(200).json(transaction);
            } else {
                span.setTag('found', false);
                res.status(404).json({ message: 'Transaction not found' });
            }
        } catch (err) {
            span.log({ event: 'error', message: err.message });
            span.setTag('error', true);
            res.status(500).json({ message: 'Error retrieving transaction', error: err.message });
        } finally {
            span.finish();
        }
    });
});

// Start Server
app.listen(port, () => {
    const timestamp = moment().unix();
    logger.info({ timestamp, msg: `App Started on Port ${port}` });
});
const transactionService = require('./TransactionService');
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const moment = require('moment');

const app = express();
const port = 8080;

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// CORS Configuration
// app.use(cors({
//     origin: 'http://expense-s3-cors.s3-website.ap-south-1.amazonaws.com',
//     methods: ['GET', 'POST', 'PUT', 'DELETE'],
//     allowedHeaders: ['Content-Type', 'Authorization'],
//     credentials: true
// }));

app.use(cors());

// Health Check
app.get('/health', (req, res) => {
    res.json("This is the health check");
});

// Add Transaction
app.post('/transaction', (req, res) => {
    try {
        const timestamp = moment().unix();
        console.log(`{ "timestamp": ${timestamp}, "msg": "Adding Expense", "amount": ${req.body.amount}, "Description": "${req.body.desc}" }`);

        const success = transactionService.addTransaction(req.body.amount, req.body.desc);

        if (success === 200) {
            res.json({ message: 'Transaction added successfully' });
        } else {
            res.status(500).json({ message: 'Failed to add transaction' });
        }
    } catch (err) {
        res.status(500).json({ message: 'Something went wrong', error: err.message });
    }
});

// Get All Transactions
app.get('/transaction', (req, res) => {
    try {
        transactionService.getAllTransactions((results) => {
            const transactionList = results.map(row => ({
                id: row.id,
                amount: row.amount,
                description: row.description
            }));

            const timestamp = moment().unix();
            console.log(`{ "timestamp": ${timestamp}, "msg": "Getting All Expenses" }`);
            console.log(`{ "expenses": ${JSON.stringify(transactionList)} }`);

            res.status(200).json({ result: transactionList });
        });
    } catch (err) {
        res.status(500).json({ message: "Could not get all transactions", error: err.message });
    }
});

// Delete All Transactions
app.delete('/transaction', (req, res) => {
    try {
        transactionService.deleteAllTransactions(() => {
            const timestamp = moment().unix();
            console.log(`{ "timestamp": ${timestamp}, "msg": "Deleted All Expenses" }`);

            res.status(200).json({ message: "All transactions deleted successfully" });
        });
    } catch (err) {
        res.status(500).json({ message: "Deleting all transactions failed", error: err.message });
    }
});

// Delete One Transaction
app.delete('/transaction/:id', (req, res) => {
    try {
        const { id } = req.params;

        transactionService.deleteTransactionById(id, () => {
            res.status(200).json({ message: `Transaction with ID ${id} deleted successfully` });
        });
    } catch (err) {
        res.status(500).json({ message: "Error deleting transaction", error: err.message });
    }
});

// Get Single Transaction
app.get('/transaction/:id', (req, res) => {
    try {
        const { id } = req.params;

        transactionService.findTransactionById(id, (result) => {
            if (result.length > 0) {
                const transaction = {
                    id: result[0].id,
                    amount: result[0].amount,
                    desc: result[0].desc
                };

                res.status(200).json(transaction);
            } else {
                res.status(404).json({ message: "Transaction not found" });
            }
        });
    } catch (err) {
        res.status(500).json({ message: "Error retrieving transaction", error: err.message });
    }
});

// Start Server
app.listen(port, () => {
    const timestamp = moment().unix();
    console.log(`{ "timestamp": ${timestamp}, "msg": "App Started on Port ${port}" }`);
});

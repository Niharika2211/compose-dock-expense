const transactionService = require('./TransactionService');
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');
const fetch = require('node-fetch');


const app = express();
const port = 8080;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());


app.use(cors({
    origin: 'http://expense-s3-cors.s3-website.ap-south-1.amazonaws.com',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true 
}));




//Health Checking
app.get('/health',(req,res)=>{
    res.json("This is the health check");
});

// ADD TRANSACTION
app.post('/api/transaction', (req,res)=>{
    var response = "";
    try{
        t=moment().unix()
        console.log("{ \"timestamp\" : %d, \"msg\", \"Adding Expense\", \"amount\" : %d, \"Description\": \"%s\" }", t, req.body.amount, req.body.desc);
        var success = transactionService.addTransaction(req.body.amount,req.body.desc);
        if (success = 200) res.json({ message: 'added transaction successfully'});
    }catch (err){
        res.json({ message: 'something went wrong', error : err.message});
    }
});

// GET ALL TRANSACTIONS
app.get('/api/transaction',(req,res)=>{
    try{
        var transactionList = [];
       transactionService.getAllTransactions(function (results) {
            //console.log("we are in the call back:");
            for (const row of results) {
                transactionList.push({ "id": row.id, "amount": row.amount, "description": row.description });
            }
            t=moment().unix()
            console.log("{ \"timestamp\" : %d, \"msg\" : \"Getting All Expenses\" }", t);
            console.log("{ \"expenses\" : %j }", transactionList);
            res.statusCode = 200;
            res.json({"result":transactionList});
        });
    }catch (err){
        res.json({message:"could not get all transactions",error: err.message});
    }
});

//DELETE ALL TRANSACTIONS
app.delete('/api/transaction',(req,res)=>{
    console.log('in delete method');
    try{
        transactionService.deleteAllTransactions(function(result){
            t=moment().unix()
            console.log("{ \"timestamp\" : %d, \"msg\" : \"Deleted All Expenses\" }", t);
            res.statusCode = 200;
            res.json({message:"delete function execution finished."})
        })
    }catch (err){
        res.json({message: "Deleting all transactions may have failed.", error:err.message});
    }
});

//DELETE ONE TRANSACTION
app.delete('/api/transaction/id', (req,res)=>{
    try{
        //probably need to do some kind of parameter checking
        transactionService.deleteTransactionById(req.body.id, function(result){
            res.statusCode = 200;
            res.json({message: `transaction with id ${req.body.id} seemingly deleted`});
        })
    } catch (err){
        res.json({message:"error deleting transaction", error: err.message});
    }
});

//GET SINGLE TRANSACTION
app.get('/api/transaction/id',(req,res)=>{
    //also probably do some kind of parameter checking here
    try{
        transactionService.findTransactionById(req.body.id,function(result){
            res.statusCode = 200;
            var id = result[0].id;
            var amt = result[0].amount;
            var desc= result[0].desc;
            res.json({"id":id,"amount":amt,"desc":desc});
        });

    }catch(err){
        res.json({message:"error retrieving transaction", error: err.message});
    }
});

  app.listen(port, () => {
    t=moment().unix()
    console.log("{ \"timestamp\" : %d, \"msg\" : \"App Started on Port %s\" }", t,  port)
  })
//
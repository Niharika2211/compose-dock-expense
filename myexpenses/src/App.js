import React, { useEffect, useState } from 'react';
import axios from 'axios';

import './App.css';

const APIURL = process.env.apiURL || "http://localhost:8080";

function App() {


  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [transactions, setTransactions] = useState([]);

  useEffect(() => {
    axios.get(`${APIURL}/api/transaction`, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      method: "POST",
      body: JSON.stringify({ amount, desc: description })
    }).then(res => {
      setTransactions(res.data.result);
    });
  }, []);
  const onAmountChange = ({ target: { value } }) => {
    setAmount(value);
  }

  const onDescriptionChange = ({ target: { value } }) => {
    setDescription(value);
  }

  const onAddClick = () => {
      axios.post(`${APIURL}/api/transaction`, {
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        method: "POST",
        body: JSON.stringify({ amount, desc: description })
      });
  }

  const onDeleteClick = () => {
    axios.delete(`${APIURL}/api/transaction`,{
      method: "DELETE",
      mode: 'no-cors',
      method: 'post',
      url: `http://localhost:8081`,
      credentials: 'include'
    });
    setAmount('');
    setDescription('');
    setTransactions([]);
  }

  return (
    <div className="App">
      <header className="App-header">
        <div style={{ margin: '10px 20px' }}>Add / View Expenses</div>
        <div>
          <input type="button" value="DEL" style={{ float: "right", marginBottom: '1em' }} onClick={onDeleteClick} />
          <table class="transactions">
            <tbody>
              <tr>
                <td>ID</td>
                <td>AMOUNT</td>
                <td>DESC</td>
              </tr>
              <tr>
                <td>
                  <input type="button" value="ADD" onClick={onAddClick} />
                </td>
                <td>
                  <input type="text" name="text_amt" value={amount} onChange={onAmountChange} />
                </td>
                <td>
                  <input type="text" name="text_desc" value={description} onChange={onDescriptionChange} />
                </td>
              </tr>
            </tbody>
          </table>
          <div style={{textAlign:'center', margin: '20px'}}>
            <table className='transactions'>
              <tbody>
                <tr>
                <td>
                    ID
                  </td>
                  <td>
                    Amount
                  </td>
                  <td>
                    Desc
                  </td>
                  </tr>
            
                  {
                    transactions.map((item) => <tr>
                      <td>{item.id}</td>
                      <td>{item.amount}</td>
                      <td>{item.description}</td>
                    </tr>)
                  }
              </tbody>
            </table>
          </div>
        </div>
      </header>
    </div>
  );
}

export default App;

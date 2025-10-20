const express = require("express");
const app = express();
const port = 3000;

app.use(express.json());

let accounts = [];

app.post("/accounts", (req, res) => {
  const { name, balance } = req.body;
  if (!name || balance == null) {
    return res.status(400).json({ message: "Name and balance are required" });
  }
  const existing = accounts.find(acc => acc.name === name);
  if (existing) return res.status(400).json({ message: "Account already exists" });
  const account = { name, balance: Number(balance) };
  accounts.push(account);
  res.status(201).json({ message: "Account created", account });
});

app.get("/accounts", (req, res) => {
  res.status(200).json(accounts);
});

app.post("/transfer", (req, res) => {
  const { from, to, amount } = req.body;
  if (!from || !to || !amount) return res.status(400).json({ message: "Missing fields" });

  const sender = accounts.find(acc => acc.name === from);
  const receiver = accounts.find(acc => acc.name === to);

  if (!sender || !receiver) return res.status(404).json({ message: "Account not found" });
  if (sender.balance < amount) return res.status(400).json({ message: "Insufficient balance in sender account" });

  sender.balance -= Number(amount);
  receiver.balance += Number(amount);

  res.status(200).json({
    message: "Transfer successful",
    from,
    to,
    amount: Number(amount),
    senderNewBalance: sender.balance,
    receiverNewBalance: receiver.balance,
  });
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

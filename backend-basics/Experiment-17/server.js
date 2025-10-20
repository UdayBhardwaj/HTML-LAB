import express from 'express';
import jwt from 'jsonwebtoken';

const app = express();
const port = 3000;

app.use(express.json());

const SECRET_KEY = 'supersecretkey';

let user = { username: 'admin', password: 'password123' };
let account = { balance: 1000 };

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === user.username && password === user.password) {
    const token = jwt.sign({ username }, SECRET_KEY, { expiresIn: '1h' });
    res.json({ message: 'Login successful', token });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ message: 'Token missing' });
  const token = authHeader.split(' ')[1];
  jwt.verify(token, SECRET_KEY, (err, userData) => {
    if (err) return res.status(403).json({ message: 'Invalid or expired token' });
    req.user = userData;
    next();
  });
}

app.get('/balance', authenticateToken, (req, res) => {
  res.json({ balance: account.balance });
});

app.post('/deposit', authenticateToken, (req, res) => {
  const { amount } = req.body;
  if (!amount || amount <= 0) return res.status(400).json({ message: 'Invalid deposit amount' });
  account.balance += amount;
  res.json({ message: 'Deposit successful', newBalance: account.balance });
});

app.post('/withdraw', authenticateToken, (req, res) => {
  const { amount } = req.body;
  if (!amount || amount <= 0) return res.status(400).json({ message: 'Invalid withdrawal amount' });
  if (amount > account.balance) return res.status(400).json({ message: 'Insufficient balance' });
  account.balance -= amount;
  res.json({ message: 'Withdrawal successful', newBalance: account.balance });
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

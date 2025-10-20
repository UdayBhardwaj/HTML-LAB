import express from 'express';
import adminRouter from './route.js';

const app = express();
const port = 3000;

function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ message: 'Authorization header missing' });
  }
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(400).json({ message: 'Invalid Authorization format. Use Bearer <token>' });
  }
  const token = parts[1];
  if (token === 'mysecrettoken') {
    next();
  } else {
    res.status(403).json({ message: 'Forbidden - Invalid token' });
  }
}

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

app.use(express.json());
app.use('/admin', authMiddleware, adminRouter);

let users = [];

app.post('/users', (req, res) => {
  const user = req.body;
  users.push(user);
  res.status(201).json({ message: 'User added', user });
});

app.get('/users', (req, res) => {
  res.status(200).json(users);
});

app.put('/users/:id', (req, res) => {
  const id = req.params.id;
  const updatedUser = req.body;
  users = users.map(user => (user.id === id ? updatedUser : user));
  res.status(200).json({ message: 'User updated', updatedUser });
});

app.delete('/users/:id', (req, res) => {
  const id = req.params.id;
  users = users.filter(user => user.id !== id);
  res.status(200).json({ message: 'User deleted' });
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

import express from 'express';
const router = express.Router();

router.use((req, res, next) => {
  console.log('Admin router middleware executed');
  next();
});

router.get('/dashboard', (req, res) => {
  res.send('Welcome to the Admin Dashboard!');
});

export default router;

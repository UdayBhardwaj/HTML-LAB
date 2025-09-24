const express = require("express");
const app = express();
const PORT = 3000;

app.use(express.json());

let cards = [];
let idCounter = 1;

app.get("/cards", (req, res) => {
  res.json(cards);
});

app.get("/cards/:id", (req, res) => {
  const card = cards.find((c) => c.id === parseInt(req.params.id));
  if (!card) {
    return res.status(404).json({ message: "Card not found" });
  }
  res.json(card);
});

app.post("/cards", (req, res) => {
  const { suit, value } = req.body;
  if (!suit || !value) {
    return res.status(400).json({ message: "Suit and value are required" });
  }
  const newCard = { id: idCounter++, suit, value };
  cards.push(newCard);
  res.status(201).json(newCard);
});

app.delete("/cards/:id", (req, res) => {
  const index = cards.findIndex((c) => c.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ message: "Card not found" });
  }
  const removed = cards.splice(index, 1);
  res.json({ message: "Card deleted", card: removed[0] });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
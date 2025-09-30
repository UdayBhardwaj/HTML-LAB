const express = require("express");
const mongoose = require("mongoose");
const productRoutes = require("./routes/productRoutes");

const app = express();
const PORT = 3000;

app.use(express.json());

mongoose.connect("mongodb://127.0.0.1:27017/productdb", {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log("✅ MongoDB Connected"))
.catch(err => console.error(err));

app.use("/products", productRoutes);

app.listen(PORT, () => console.log(`🚀 Server running at http://localhost:${PORT}`));

const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

// GET all products
router.get("/", async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET a single product by ID
router.get("/:id", async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json(product);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST create multiple products
router.post("/", async (req, res) => {
  try {
    const products = req.body; // expects an array of products
    const savedProducts = await Product.insertMany(products, { ordered: false }); // ignores duplicates
    res.status(201).json(savedProducts);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT update a product by ID
router.put("/:id", async (req, res) => {
  try {
    const { name, price, category, variants } = req.body;
    const updatedProduct = await Product.findByIdAndUpdate(
      req.params.id,
      { name, price, category, variants },
      { new: true, runValidators: true }
    );
    if (!updatedProduct) return res.status(404).json({ message: "Product not found" });
    res.json(updatedProduct);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE a product by ID
router.delete("/:id", async (req, res) => {
  try {
    const deletedProduct = await Product.findByIdAndDelete(req.params.id);
    if (!deletedProduct) return res.status(404).json({ message: "Product not found" });
    res.json({ message: "Product deleted successfully", product: deletedProduct });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

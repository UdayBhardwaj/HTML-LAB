const mongoose = require("mongoose");

const variantSchema = new mongoose.Schema({
  color: { type: String, required: true },
  size: { type: String, required: true },
  stock: { type: Number, required: true, min: 0 }
});

const productSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, unique: true }, // unique ensures no duplicates
  price: { type: Number, required: true, min: 0 },
  category: { type: String, required: true },
  variants: [variantSchema] // nested array of variants
}, { timestamps: true });

module.exports = mongoose.model("Product", productSchema);

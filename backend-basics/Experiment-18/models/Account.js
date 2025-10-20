import mongoose from 'mongoose';

const accountSchema = new mongoose.Schema({
  name: String,
  balance: Number
});

const Account = mongoose.model('Account', accountSchema);
export default Account;

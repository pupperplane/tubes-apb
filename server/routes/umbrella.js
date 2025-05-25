const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = './data/umbrellas.json';

router.get('/', (req, res) => {
  const data = fs.readFileSync(path);
  res.json(JSON.parse(data));
});

router.post('/borrow', (req, res) => {
  const data = JSON.parse(fs.readFileSync(path));
  const available = data.find(u => u.status === 'available');
  if (available) {
    available.status = 'borrowed';
    fs.writeFileSync(path, JSON.stringify(data));
    res.json({ message: 'Payung berhasil dipinjam', id: available.id });
  } else {
    res.status(400).json({ message: 'Tidak ada payung tersedia' });
  }
});

module.exports = router;

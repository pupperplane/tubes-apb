const express = require('express');
const cors = require('cors');
const app = express();
const umbrellaRoutes = require('./routes/umbrella');

app.use(cors());
app.use(express.json());
app.use('/api/umbrella', umbrellaRoutes);

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Umbrella server running on port ${PORT}`);
});

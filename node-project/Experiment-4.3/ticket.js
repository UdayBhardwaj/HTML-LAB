const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const PORT = 3000;

// In-memory seat storage
// status: 'available', 'locked', 'booked'
const seats = [
    { id: 1, status: 'available', lockedBy: null, lockExpiresAt: null },
    { id: 2, status: 'available', lockedBy: null, lockExpiresAt: null },
    { id: 3, status: 'available', lockedBy: null, lockExpiresAt: null },
    { id: 4, status: 'available', lockedBy: null, lockExpiresAt: null },
    { id: 5, status: 'available', lockedBy: null, lockExpiresAt: null }
];

// Helper function to clean expired locks
function cleanExpiredLocks() {
    const now = Date.now();
    seats.forEach(seat => {
        if (seat.status === 'locked' && seat.lockExpiresAt <= now) {
            seat.status = 'available';
            seat.lockedBy = null;
            seat.lockExpiresAt = null;
        }
    });
}

// View all seats
app.get('/seats', (req, res) => {
    cleanExpiredLocks();
    res.json(seats);
});

// Lock a seat
app.post('/lock', (req, res) => {
    const { seatId, userId } = req.body;
    cleanExpiredLocks();

    const seat = seats.find(s => s.id === seatId);
    if (!seat) return res.status(404).json({ message: 'Seat not found' });

    if (seat.status === 'booked') return res.status(400).json({ message: 'Seat already booked' });
    if (seat.status === 'locked') return res.status(400).json({ message: 'Seat already locked' });

    seat.status = 'locked';
    seat.lockedBy = userId;
    seat.lockExpiresAt = Date.now() + 60000; // 1 minute lock

    res.json({ message: `Seat ${seatId} locked for user ${userId}` });
});

// Confirm booking
app.post('/confirm', (req, res) => {
    const { seatId, userId } = req.body;
    cleanExpiredLocks();

    const seat = seats.find(s => s.id === seatId);
    if (!seat) return res.status(404).json({ message: 'Seat not found' });

    if (seat.status !== 'locked') return res.status(400).json({ message: 'Seat is not locked' });
    if (seat.lockedBy !== userId) return res.status(403).json({ message: 'You did not lock this seat' });

    seat.status = 'booked';
    seat.lockedBy = null;
    seat.lockExpiresAt = null;

    res.json({ message: `Seat ${seatId} successfully booked by user ${userId}` });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
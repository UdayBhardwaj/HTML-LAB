import { useState } from "react";

function LibraryManagement() {
  const [books, setBooks] = useState([
    { title: "1984", author: "George Orwell" },
    { title: "The Great Gatsby", author: "F. Scott Fitzgerald" },
    { title: "To Kill a Mockingbird", author: "Harper Lee" },
  ]);

  return (
    <div style={{ border: "1px solid black", padding: "15px", margin: "10px" }}>
      <h2>Library Management</h2>
      <ul>
        {books.map((book, idx) => (
          <li key={idx}>{book.title} by {book.author}</li>
        ))}
      </ul>
    </div>
  );
}

export default LibraryManagement;

import React, { useState } from "react";
import "./App.css";

function App() {
  const [books, setBooks] = useState([
    { title: "1984", author: "George Orwell" },
    { title: "The Great Gatsby", author: "F. Scott Fitzgerald" },
    { title: "To Kill a Mockingbird", author: "Harper Lee" },
  ]);

  const [searchText, setSearchText] = useState("");
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");

  // Add book
  const addBook = () => {
    if (title !== "" && author !== "") {
      setBooks([...books, { title: title, author: author }]);
      setTitle("");
      setAuthor("");
    }
  };

  // Remove book
  const removeBook = (index) => {
    const copy = [...books];
    copy.splice(index, 1);
    setBooks(copy);
  };

  // Filter books
  const filteredBooks = books.filter((book) =>
    (book.title + " " + book.author).toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <div className="container">
      <h2>Library Management</h2>

      <input
        type="text"
        placeholder="Search by title or author"
        value={searchText}
        onChange={(e) => setSearchText(e.target.value)}
      />

      <br />

      <input
        type="text"
        placeholder="New book title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />
      <input
        type="text"
        placeholder="New book author"
        value={author}
        onChange={(e) => setAuthor(e.target.value)}
      />
      <button onClick={addBook}>Add Book</button>

      <div className="book-list">
        {filteredBooks.map((book, index) => (
          <div key={index} className="book-item">
            <span>
              <b>{book.title}</b> by {book.author}
            </span>
            <button onClick={() => removeBook(index)}>Remove</button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;

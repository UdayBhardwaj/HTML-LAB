import React from "react";

class Person {
  constructor(name, age) {
    this.name = name;
    this.age = age;
  }

  displayInfo() {
    return `Name: ${this.name}, Age: ${this.age}`;
  }
}

class Student extends Person {
  constructor(name, age, course) {
    super(name, age);
    this.course = course;
  }

  displayInfo() {
    return `Student -> Name: ${this.name}, Age: ${this.age}, Course: ${this.course}`;
  }
}

class Teacher extends Person {
  constructor(name, age, subject) {
    super(name, age);
    this.subject = subject;
  }

  displayInfo() {
    return `Teacher -> Name: ${this.name}, Age: ${this.age}, Subject: ${this.subject}`;
  }
}

export default function App() {
  
  const student1 = new Student("Uday ", 20, "Computer Science");
  const teacher1 = new Teacher("Dr Singh", 40, "CS");

  return (
    <div style={{ margin: "20px", fontFamily: "Arial" }}>
      <h2>Experiment 9: Person Class Hierarchy</h2>
      <p>{student1.displayInfo()}</p>
      <p>{teacher1.displayInfo()}</p>
    </div>
  );
}

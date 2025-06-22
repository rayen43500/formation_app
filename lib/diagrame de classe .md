```mermaid
classDiagram
    class Person {
        -String name
        -int age
        -String email
        -String phoneNumber
        -String address
        +getName() String
        +setName(String name) void
        +getAge() int
        +setAge(int age) void
        +getContactInfo() String
    }
    
    class Student {
        -int studentId
        -String major
        -Date enrollmentDate
        -float gpa
        -boolean isActive
        +getStudentId() int
        +getMajor() String
        +getEnrollmentDate() Date
        +calculateGPA() float
        +registerForCourse(Course course) boolean
        +viewTranscript() Transcript
    }
    
    class Teacher {
        -String subject
        -int employeeId
        -String department
        -int yearsOfExperience
        -String[] qualifications
        +getSubject() String
        +setSubject(String subject) void
        +getDepartment() String
        +assignGrade(Student student, Course course, String grade) void
    }
    
    class Course {
        -String courseCode
        -String title
        -int credits
        -String description
        -String[] prerequisites
        -int maxCapacity
        -boolean isActive
        +getCourseCode() String
        +getTitle() String
        +getCredits() int
        +getDescription() String
        +checkPrerequisites(Student student) boolean
        +getAvailableSeats() int
    }
    
    class Department {
        -String name
        -String code
        -Teacher headOfDepartment
        +getName() String
        +getCourses() Course[]
        +getTeachers() Teacher[]
    }
    
    class Enrollment {
        -Student student
        -Course course
        -Date enrollmentDate
        -String grade
        -boolean isCompleted
        +getGrade() String
        +setGrade(String grade) void
        +isPassingGrade() boolean
    }
    
    class Transcript {
        -Student student
        -Enrollment[] enrollments
        -float cumulativeGPA
        +calculateGPA() float
        +printTranscript() void
        +getCompletedCourses() Course[]
    }
    
    Person <|-- Student : inheritance
    Person <|-- Teacher : inheritance
    Student "1" -- "*" Enrollment : has
    Course "1" -- "*" Enrollment : has
    Department "1" -- "*" Course : offers
    Department "1" -- "*" Teacher : employs
    Student "1" -- "1" Transcript : has
    Enrollment "*" -- "1" Transcript : included in

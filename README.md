Some practice using the previous contact manager app. Converted it from a file system to use a SQL database.
- Exposed the API the app was using to work with data, and separated that into its own class
- Then converted those calls to work with PG gem, then with Sequel.
- Used each step to think through how the application is interfacing with the underlying data.
- Was unable to fully update the tests to work with the database, as it would complain about too many connections.
- Even after including database disconnect logic in the teardown step of the test, would inevitably run into this.
- Light googling indicated that generally you don't want to use database calls for tests anyway.
- For now, the question of how to write tests in the context of a database is a question for another day.

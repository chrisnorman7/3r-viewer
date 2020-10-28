import 'volunteer.dart';

class News {
  News(
    {
      this.title,
      this.body,
      this.sticky,
      this.creator,
      this.date,
    }
  );

    String title, body;
    bool sticky;
    Volunteer creator;
    DateTime date;
}

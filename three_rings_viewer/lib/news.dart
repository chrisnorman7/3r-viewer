import 'volunteer.dart';

class News {
  News(
    {
      this.title,
      this.body,
      this.sticky,
      this.creator,
    }
  );

    String title, body;
    bool sticky;
    Volunteer creator;
}

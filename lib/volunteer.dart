import 'package:flutter/material.dart';

import 'constants.dart';
import 'util.dart';

class Volunteer {
  Volunteer(
    {
      this.id,
      this.name,
    }
  );

  final int id;
  final String name;
  
  Image get image {
    return Image.network(
      '$baseUrl/directory/$id/photos/thumb.jpg',
      headers: getHeaders(),
    );
  }
}

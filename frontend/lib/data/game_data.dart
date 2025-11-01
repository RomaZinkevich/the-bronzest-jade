import 'package:guess_who/models/character.dart';

class GameData {
  static List<Character> getSampleCharacters() {
    return [
      Character(
        id: '1',
        name: 'Alex',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Alex',
      ),
      Character(
        id: '2',
        name: 'Emma',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Emma',
      ),
      Character(
        id: '3',
        name: 'Bob',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Bob',
      ),
      Character(
        id: '4',
        name: 'Sarah',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Sarah',
      ),
      Character(
        id: '5',
        name: 'Mike',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Mike',
      ),
      Character(
        id: '6',
        name: 'Lisa',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Lisa',
      ),
      Character(
        id: '7',
        name: 'David',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=David',
      ),
      Character(
        id: '8',
        name: 'Anna',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Anna',
      ),
      Character(
        id: '9',
        name: 'Tom',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Tom',
      ),
      Character(
        id: '10',
        name: 'Sophie',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Sophie',
      ),
      Character(
        id: '11',
        name: 'James',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=James',
      ),
      Character(
        id: '12',
        name: 'Olivia',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Olivia',
      ),
      Character(
        id: '13',
        name: 'Chris',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Chris',
      ),
      Character(
        id: '14',
        name: 'Mia',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Mia',
      ),
      Character(
        id: '15',
        name: 'Ryan',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Ryan',
      ),
      Character(
        id: '16',
        name: 'Zoe',
        imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Zoe',
      ),
    ];
  }

  // TODO: Replace with API call to your Spring Boot backend
  // static Future<List<Character>> fetchCharacters() async {
  //   final response = await http.get(Uri.parse('/api/characters'));
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = json.decode(response.body);
  //     return data.map((json) => Character.fromJson(json)).toList();
  //   }
  //   throw Exception('Failed to load characters');
  // }
}

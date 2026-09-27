import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final file = File(r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\update_accept_urgent_offer_no_pin.sql');
  final sql = await file.readAsString();

  final connection = PostgreSQLConnection(
    'aws-0-ap-south-1.pooler.supabase.com',
    6543,
    'postgres',
    username: 'postgres.nmbzckjmdszohkttnjis',
    password: 'E#Dk5*g@b_sXyL\$9@',
  );

  await connection.open();
  print('Connected to database.');

  try {
    await connection.query(sql);
    print('SQL executed successfully.');
  } catch (e) {
    print('Error executing SQL: \$e');
  } finally {
    await connection.close();
    print('Connection closed.');
  }
}

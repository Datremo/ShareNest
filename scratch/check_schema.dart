import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'aws-0-ap-south-1.pooler.supabase.com',
    6543,
    'postgres',
    username: 'postgres.nmbzckjmdszohkttnjis',
    password: 'E#Dk5*g@b_sXyL\$9@',
  );

  await connection.open();
  
  try {
    var result = await connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'listings';
    ''');
    print('--- listings ---');
    for (var row in result) {
      print(row);
    }
    
    result = await connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'urgent_request_offers';
    ''');
    print('\\n--- urgent_request_offers ---');
    for (var row in result) {
      print(row);
    }
  } catch (e) {
    print('Error executing SQL: \$e');
  } finally {
    await connection.close();
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ✅ Screen imports
import 'screens/splash_screen.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/farmer.dart';
import 'screens/retailer.dart';
import 'screens/add_produce_page.dart';
import 'screens/suggestions_page.dart';
import 'screens/disease_page.dart';
import 'screens/conversations_page.dart';
import 'screens/profile_page.dart';
import 'screens/earnings_page.dart';
import 'screens/changepassword_page.dart';
import 'screens/languages_page.dart';
import 'screens/negotiations_farmer_page.dart';
import 'screens/addtocart_page.dart';
import 'screens/payment_page.dart';
import 'screens/order_page.dart';
import 'screens/negotiate_page.dart';
import 'screens/notification_page.dart';
import 'screens/SignupScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // ✅ Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_KEY']; // Changed from SUPABASE_KEY to SUPABASE_ANON_KEY

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('❌ Missing Supabase environment variables in .env file.\n'
          'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    runApp(const NammaRaithaApp());
  } catch (e) {
    // If there's an error during initialization, we still run the app but show an error screen
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}

class NammaRaithaApp extends StatelessWidget {
  const NammaRaithaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namma Raitha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/farmerDashboard': (context) => const FarmerDashboard(),
        '/retailerDashboard': (context) => const RetailerDashboard(),
        '/add_produce': (context) => const AddProducePage(),
        '/suggestions': (context) => const SuggestionsPage(),
        '/disease': (context) => const DiseasePage(),
        '/conversations': (context) => const ConversationList(),
        '/profile':(context) => const ProfilePage(),
        '/earnings': (context) => const EarningsPage(), // Add this
        '/changePassword': (context) => const ChangePasswordPage(),
        '/languages': (context) => const LanguageSelectorPage(),
        '/cart':(context) => const AddToCartScreen(),
        '/orders':(context) => const AmazonStyleOrderPage(),
        '/notifications': (context) => const NotificationScreen(),
        '/signup': (context)=> const SignupScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle the negotiateR route with parameters
        if (settings.name == '/negotiateR') {
  final args = settings.arguments as Map<String, dynamic>?;

  if (args == null) {
    // Handle missing arguments gracefully
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text("Missing chat parameters"),
        ),
      ),
    );
  }

  return MaterialPageRoute(
    builder: (context) => NegotiationChatPage(
      cropId: args['cropId'] as String,
      farmerId: args['farmerId'] as String,
      retailerId: args['retailerId'] as String,
      currentUserId: args['currentUserId'] as String,
      cropName: args['cropName'] as String? ?? "",
      farmerName: args['farmerName'] as String? ?? "",
      retailerName: args['retailerName'] as String? ?? "",
    ),
  );
}

        
        // Handle the payment route with parameters
        if (settings.name == '/payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentPage(
              cartItems: args['cartItems'],
              totalAmount: args['totalAmount'],
            ),
          );
        }
        
        // Handle the negotiation route with parameters
        if (settings.name == '/negotiation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => NegotiationChat(
              conversationId: args['conversationId'],
              cropId: args['cropId'],
              retailerId: args['retailerId'],
              cropName: args['cropName'],
              retailerName: args['retailerName'],
            ),
          );
        }
        
        // Return null for unknown routes to trigger onUnknownRoute
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Route not found'),
            ),
          ),
        );
      },
    );
  }
}

// Error screen to show if initialization fails
class ErrorApp extends StatelessWidget {
  final String errorMessage;
  
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
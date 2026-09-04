import SwiftUI

enum AnnotationItem: Equatable {
    case circle(Color)
    case note(String)
}

struct SavedArticle: Identifiable, Equatable {
    let id: UUID
    let title: String
    let author: String
    let publication: String // Asset name for publisher logo
    let date: Date
    let dateString: String
    let imageURL: URL?
    let annotation: AnnotationItem?
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        publication: String,
        date: Date = Date(),
        dateString: String,
        imageURLString: String? = nil,
        annotation: AnnotationItem? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.publication = publication
        self.date = date
        self.dateString = dateString
        if let str = imageURLString, let url = URL(string: str) {
            self.imageURL = url
        } else {
            self.imageURL = nil
        }
        self.annotation = annotation
    }
}

enum SavedMockData {
    static let savedArticles: [SavedArticle] = [
        SavedArticle(
            title: "New App Connects Local Farmers Directly With Consumers for Fresher Produce",
            author: "Brendan Cosgrove",
            publication: "NY Times",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            dateString: "Yesterday",
            imageURLString: "https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Defense Tech Startups Win Billions in New Pentagon Contracts",
            author: "Alex Heath",
            publication: "Wall Street Journal",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            dateString: "2 days ago",
            imageURLString: "https://images.unsplash.com/photo-1579965342575-16428a7c8881?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "South Korea’s Chip Giants Face Tightening Export Controls",
            author: "Michelle Ye Hee Lee",
            publication: "Financial Times",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            dateString: "3 days ago",
            imageURLString: "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Tesla Bets Entire Valuation on Robotaxi Network Ahead of Event",
            author: "Rebecca Elliott",
            publication: "The Economist",
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            dateString: "4 days ago",
            imageURLString: "https://images.unsplash.com/photo-1563720223185-11003d516935?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Federal Reserve Signals Slower Rate Cuts Amid Resilient Economic Growth",
            author: "Nick Timiraos",
            publication: "Wall Street Journal",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            dateString: "5 days ago",
            imageURLString: "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "OpenAI Unveils Reasoning Models Capable of Complex Scientific Tasks",
            author: "Cade Metz",
            publication: "NY Times",
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            dateString: "6 days ago",
            imageURLString: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Global Shipping Diverts from Red Sea as Geopolitical Risks Mount",
            author: "Costas Paris",
            publication: "The Washington Post",
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            dateString: "1 week ago",
            imageURLString: "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Venture Capital Inflows Hit New Record for Clean Energy Projects",
            author: "Gillian Tett",
            publication: "Financial Times",
            date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
            dateString: "1 week ago",
            imageURLString: "https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Commercial Real Estate Loan Defaults Rise in Major Metros",
            author: "Konrad Putzier",
            publication: "Barron’s",
            date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
            dateString: "2 weeks ago",
            imageURLString: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=800&auto=format&fit=crop"
        ),
        SavedArticle(
            title: "Electric Aviation Startup Completes First Autonomous Test Flight",
            author: "Andrew Tangel",
            publication: "CNBC",
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            dateString: "2 weeks ago",
            imageURLString: "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?q=80&w=800&auto=format&fit=crop"
        )
    ]
    
    static let annotatedArticles: [SavedArticle] = [
        SavedArticle(
            title: "New App Connects Local Farmers Directly With Consumers for Fresher Produce",
            author: "Brendan Cosgrove",
            publication: "NY Times",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            dateString: "Yesterday",
            imageURLString: "https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 0.204, green: 0.780, blue: 0.349)) // #34C759 Green
        ),
        SavedArticle(
            title: "Defense Tech Startups Win Billions in New Pentagon Contracts",
            author: "Alex Heath",
            publication: "Wall Street Journal",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            dateString: "2 days ago",
            imageURLString: "https://images.unsplash.com/photo-1579965342575-16428a7c8881?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 0.0, green: 0.478, blue: 1.0)) // #007AFF Blue
        ),
        SavedArticle(
            title: "South Korea’s Chip Giants Face Tightening Export Controls",
            author: "Michelle Ye Hee Lee",
            publication: "Financial Times",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            dateString: "3 days ago",
            imageURLString: "https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 1.0, green: 0.8, blue: 0.0)) // #FFCC00 Yellow
        ),
        SavedArticle(
            title: "Tesla Bets Entire Valuation on Robotaxi Network Ahead of Event",
            author: "Rebecca Elliott",
            publication: "The Economist",
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            dateString: "4 days ago",
            imageURLString: "https://images.unsplash.com/photo-1563720223185-11003d516935?q=80&w=800&auto=format&fit=crop",
            annotation: .note("Key thesis on FSD regulatory approval timeline")
        ),
        SavedArticle(
            title: "Federal Reserve Signals Slower Rate Cuts Amid Resilient Economic Growth",
            author: "Nick Timiraos",
            publication: "Wall Street Journal",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            dateString: "5 days ago",
            imageURLString: "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 0.204, green: 0.780, blue: 0.349)) // Green
        ),
        SavedArticle(
            title: "OpenAI Unveils Reasoning Models Capable of Complex Scientific Tasks",
            author: "Cade Metz",
            publication: "NY Times",
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            dateString: "6 days ago",
            imageURLString: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 0.0, green: 0.478, blue: 1.0)) // Blue
        ),
        SavedArticle(
            title: "Global Shipping Diverts from Red Sea as Geopolitical Risks Mount",
            author: "Costas Paris",
            publication: "The Washington Post",
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            dateString: "1 week ago",
            imageURLString: "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=800&auto=format&fit=crop",
            annotation: .note("Rerouting through Cape of Good Hope adds 12 days")
        ),
        SavedArticle(
            title: "Venture Capital Inflows Hit New Record for Clean Energy Projects",
            author: "Gillian Tett",
            publication: "Financial Times",
            date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
            dateString: "1 week ago",
            imageURLString: "https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
        ),
        SavedArticle(
            title: "Commercial Real Estate Loan Defaults Rise in Major Metros",
            author: "Konrad Putzier",
            publication: "Barron’s",
            date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
            dateString: "2 weeks ago",
            imageURLString: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=800&auto=format&fit=crop",
            annotation: .circle(Color(red: 0.686, green: 0.322, blue: 0.871)) // Purple
        ),
        SavedArticle(
            title: "Electric Aviation Startup Completes First Autonomous Test Flight",
            author: "Andrew Tangel",
            publication: "CNBC",
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            dateString: "2 weeks ago",
            imageURLString: "https://images.unsplash.com/photo-1506015391300-4802dc74de2e?q=80&w=800&auto=format&fit=crop",
            annotation: .note("Battery density breakthrough reaches 450 Wh/kg")
        )
    ]
}

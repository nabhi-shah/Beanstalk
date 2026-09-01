import Foundation

struct MockData {
    static let articles: [Article] = [
        Article(
            publication: "NY Times",
            author: "Shane Goldmacher",
            date: "Sun, 23 Aug 2026",
            title: "The Data Center Backlash Bursts Into the Midterms",
            content: "With opposition to the centers mounting, many Democrats and a growing number of Republicans are campaigning against them.\n\nOfficials in Valgaria and the neighboring Republic of Kestrel confirmed the operation only after images of the damaged facilities began circulating on regional networks, according to three people briefed on the discussions. The decision followed weeks of internal debate in both capitals, where leaders had resisted direct involvement out of concern that visible participation would invite reprisals against energy infrastructure along the coast.\n\nThe coordination marks a shift for a region long defined by its reluctance to act collectively. Defense officials from four countries have met twice since spring to discuss shared early-warning systems, people familiar with those talks said, though no formal agreement has been signed. Analysts caution that the cooperation remains fragile and largely improvised, driven more by immediate threat than by any durable alignment of interests.\n\nThe strikes have complicated an already unsettled diplomatic picture. Two of the...",
            aiSummary: "Politicians from both major parties are increasingly campaigning against the construction of new data centers as local opposition grows due to environmental and infrastructural concerns, making it a surprising issue in the midterm elections.",
            thumbnailURLString: "https://static01.nyt.com/images/2026/08/23/multimedia/23data-centers-promo-hp-hltm/23data-centers-promo-hp-hltm-mediumSquareAt3X.jpg"
        ),
        Article(
            publication: "NY Times",
            author: "Maggie Haberman and Annie Karni",
            date: "Sun, 23 Aug 2026",
            title: "Jeffries and Kushner Meet Privately as Midterm Attacks Fly",
            content: "President Trump’s son-in-law and the man in line to be speaker of a Democratic-led House discussed how Democrats and the administration could work together.",
            aiSummary: "In a rare moment of bipartisan discussion amidst heated midterm campaigns, Jared Kushner and Hakeem Jeffries held a private meeting to explore potential avenues of cooperation between a prospective Democratic-led House and the current administration.",
            thumbnailURLString: "https://static01.nyt.com/images/2026/08/23/us/promo-hakeem/promo-hakeem-mediumSquareAt3X.png"
        ),
        Article(
            publication: "NY Times",
            author: "Campbell Robertson and Jessica Contrera",
            date: "Sun, 23 Aug 2026",
            title: "Angry Ohio Voters Could Turn Their State Purple Again",
            content: "A governor’s race, a Senate contest and enough congressional contests to swing control of the House are all in play in Ohio, where voters of all stripes express a deep sense of powerlessness.",
            aiSummary: "Driven by widespread frustration and a feeling of powerlessness, Ohio voters are poised to make the traditionally Republican-leaning state highly competitive in the upcoming elections, with major implications for control of the House and Senate.",
            thumbnailURLString: "https://static01.nyt.com/images/2026/08/23/multimedia/23nat-ohio-politics-top-bkgv/23nat-ohio-politics-top-bkgv-mediumSquareAt3X.jpg"
        ),
        Article(
            publication: "CNBC",
            author: "",
            date: "Sun, 23 Aug 2026",
            title: "After 10 years at United, CEO Scott Kirby is thinking big about the future of his airline from JFK to AI",
            content: "United Airlines CEO Scott Kirby talked to CNBC in a wide-ranging interview about his proposed airline megadeals, AI and the future of the carrier.",
            aiSummary: "United Airlines CEO Scott Kirby shares his ambitious vision for the airline's next decade, focusing on potential megadeals, leveraging artificial intelligence, and strategic expansions like returning to JFK airport.",
            thumbnailURLString: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "CNBC",
            author: "",
            date: "Sun, 23 Aug 2026",
            title: "Wells Fargo and Citigroup have room to buy a big bank. These 5 regionals fit the bill",
            content: "Citigroup and Wells Fargo have room to buy a big regional bank as regulators have opened the door to megadeals. Five regional banks make sense as targets.",
            aiSummary: "As regulatory hurdles ease for banking megadeals, financial giants Citigroup and Wells Fargo are positioned to acquire large regional banks, with five specific regional institutions identified as prime acquisition targets.",
            thumbnailURLString: "https://images.unsplash.com/photo-1601597111158-2fceff292cdc?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "CNBC",
            author: "",
            date: "Sat, 22 Aug 2026",
            title: "Trump reshuffled his portfolio in June, selling names like Meta and buying Berkshire Hathaway",
            content: "President Donald Trump disclosed just over 1,000 financial transactions in the month of June in what appears to be broad reshuffling of his portfolio.",
            aiSummary: "Financial disclosures reveal that Donald Trump significantly restructured his investment portfolio in June, executing over a thousand transactions which included liquidating positions in tech giants like Meta while acquiring shares in Berkshire Hathaway.",
            thumbnailURLString: "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "Wall Street Journal",
            author: "",
            date: "Mon, 27 Jan 2025",
            title: "Palestinians Stream Back to Northern Gaza on Foot",
            content: "Israel allowed displaced Gazans to begin crossing a military zone that bisects the enclave after a deadlock over hostage releases was broken.",
            aiSummary: "Following a breakthrough in hostage release negotiations, displaced Palestinians have begun returning to northern Gaza on foot as Israeli forces permit civilian movement across a previously restricted military zone.",
            thumbnailURLString: "https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "Wall Street Journal",
            author: "",
            date: "Mon, 27 Jan 2025",
            title: "Leading China Property Developer Reports Huge loss, in Sign of Widening Real-Estate Woes",
            content: "Troubles at Vanke raise questions about the continued spread of the property crisis and whether the Chinese state will step in.",
            aiSummary: "Vanke, a major Chinese property developer, has reported massive financial losses, intensifying concerns over China's deepening real-estate crisis and sparking debate on whether Beijing will intervene to stabilize the market.",
            thumbnailURLString: "https://images.unsplash.com/photo-1503387762-592deb58ef4e?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "The Washington Post",
            author: "Terrence McCoy",
            date: "Sat, 22 Aug 2026",
            title: "She’s a Trump acolyte. He’s a ‘gringo Sandinista.’ Meet the Harps.",
            content: "Trump aide Natalie Harp is estranged from her brother, Preston, who has used social media and recent interviews to criticize her and highlight his own left-wing politics.",
            aiSummary: "A deep political and personal divide has estranged Trump aide Natalie Harp from her brother Preston, who embraces radical left-wing politics and actively uses his public platform to criticize his sister's conservative alignment.",
            thumbnailURLString: "https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?q=80&w=2000&auto=format&fit=crop"
        ),
        Article(
            publication: "The Washington Post",
            author: "Sammy Westfall, Meg Kelly, Lior Soroka, Karen DeYoung",
            date: "Fri, 21 Aug 2026",
            title: "Israel probes killing of Hind Rajab, Gaza child who called for help",
            content: "An Israeli fact-finding mission declined to refer some other “exceptional” cases, including the killing of World Central Kitchen aid workers, to military prosecutors.",
            aiSummary: "Israeli authorities are investigating the tragic death of Hind Rajab, a child in Gaza whose desperate calls for help gained global attention, even as other controversial incidents involving civilian and aid worker casualties bypass military prosecution.",
            thumbnailURLString: "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?q=80&w=2000&auto=format&fit=crop"
        )
    ]
}

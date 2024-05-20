import SwiftUI
import CoreData
import AlertToast

struct Reading: Identifiable {
    let id: UUID
    let title: String
    let content: String
}

struct ContentView: View {
    @State private var showMainMenu = true
    @State private var selectedReading: Reading?
    @State private var selectedTab = 0 // Track selected tab
    @State private var showToast = false // State for showing the toast
    @State private var toastMessage = "" // State for the toast message

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReadingEntity.title, ascending: true)],
        animation: .default)
    private var libraryReadings: FetchedResults<ReadingEntity>

    private let readings: [Reading] = [
        Reading(id: UUID(), title: "You can't wait for everything to be perfect to start living your life.", content: "In my younger and more vulnerable years, my father gave me some advice that I've been turning over in my mind ever since. \"Whenever you feel like criticizing anyone,\" he told me, \"just remember that all the people in this world haven't had the advantages that you've had.\""),
        Reading(id: UUID(), title: "Excerpt from 'Romeo and Juliet'", content: "But soft! What light through yonder window breaks? It is the east, and Juliet is the sun. Arise, fair sun, and kill the envious moon, who is already sick and pale with grief."),
        Reading(id: UUID(), title: "Excerpt from 'To Kill a Mockingbird'", content: "Atticus, he was real nice. \"Most people are, Scout, when you finally see them.\""),
        // Add more readings as needed
    ]

    var body: some View {
        ZStack {
            Color("AppCyan").edgesIgnoringSafeArea(.all)
            if showMainMenu {
                mainMenu
            } else {
                readingView
            }
            bottomNavBar // Add bottom navigation bar
        }
        .environment(\.colorScheme, .light) // Force light mode
        .toast(isPresenting: $showToast) { // Toast notification
            AlertToast(type: .complete(Color.green), title: toastMessage)
        }
    }

    var mainMenu: some View {
        VStack {
            ForEach(readings.indices, id: \.self) { index in
                Button(action: {
                    self.selectedReading = readings[index]
                    self.showMainMenu = false
                }) {
                    VStack {
                        Image("reading\(index + 1)_background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        Text("Reading \(index + 1)")
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .padding()
    }

    var readingView: some View {
        VStack {
            Button(action: {
                self.showMainMenu = true
            }) {
                Text("Back to Menu")
                    .foregroundColor(Color("AppCyan"))
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading) {
                    Text(selectedReading?.title ?? "")
                        .font(.title)
                        .padding(.bottom)

                    Text(selectedReading?.content ?? "")
                        .font(.body)
                        .padding()
                }
            }
            .padding()

            Button(action: addReadingToLibrary) {
                Text("Add to Library")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }

    var bottomNavBar: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ScrollView {
                    VStack {
                        // Spacer to push content below navigation title
                        VStack {
                            Spacer()
                                .padding(.bottom, 20) // Add padding below the Spacer
                        }
                        
                        // Read of the Week section
                        VStack(alignment: .leading) {
                            Text("Read of the Week")
                                .font(.headline)
                                .padding()
                            NavigationLink(destination: ReadingDetailView(reading: readings.first!, isFromLibrary: false, addToLibrary: { addReadingToLibrary(readings.first!) }, removeFromLibrary: nil)) {
                                Rectangle()
                                    .fill(Color.blue)
                                    .cornerRadius(10)
                                    .frame(height: UIScreen.main.bounds.height / 2) // Half the screen height
                                    .padding(15)
                                    .overlay(
                                        Text(readings.first?.title ?? "No Reading")
                                            .font(.title)
                                            .padding(50)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle()) // Use a plain button style for the navigation link

                        }
                        .frame(height: UIScreen.main.bounds.height / 2) // Half the screen height
                        
                        
                        // Editor's Choices section
                        VStack(alignment: .leading) {
                            Text("Editor's Choices")
                                .font(.headline)
                                .padding(.leading)
                                .padding(.top, 40)
                                .padding(.bottom, 0)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(readings.prefix(5)) { reading in
                                        NavigationLink(destination: ReadingDetailView(reading: reading, isFromLibrary: false, addToLibrary: { addReadingToLibrary(reading) }, removeFromLibrary: nil)) {
                                            VStack(alignment: .leading) {
                                                Text(reading.title)
                                                    .font(.headline)
                                                Text(reading.content)
                                                    .font(.subheadline)
                                                    .lineLimit(2)
                                            }
                                            .frame(width: 150, height: 200) // Fixed size for horizontal scrolling
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                        }
                                        .buttonStyle(PlainButtonStyle()) // Use a plain button style for the navigation link
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Home")
                }
                .padding(.bottom) // Add bottom padding
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0)




            NavigationView {
                List(readings) { reading in
                    NavigationLink(destination: ReadingDetailView(reading: reading, isFromLibrary: false, addToLibrary: { addReadingToLibrary(reading) }, removeFromLibrary: nil)) {
                        VStack(alignment: .leading) {
                            Text(reading.title)
                                .font(.headline)
                            Text(reading.content)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                    }
                }
                .navigationTitle("Today's Readings")
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Today")
            }
            .tag(1)

            NavigationView {
                if libraryReadings.isEmpty {
                    Text("Library is Empty")
                        .font(.title)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(libraryReadings) { readingEntity in
                        NavigationLink(destination: ReadingDetailView(
                            reading: Reading(id: readingEntity.id!, title: readingEntity.title!, content: readingEntity.content!),
                            isFromLibrary: true,
                            addToLibrary: nil,
                            removeFromLibrary: { removeReadingFromLibrary(readingEntity) })) {
                            VStack(alignment: .leading) {
                                Text(readingEntity.title ?? "")
                                    .font(.headline)
                                Text(readingEntity.content ?? "")
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .navigationTitle("Library")
                }
            }
            .tabItem {
                Image(systemName: "book")
                Text("Library")
            }
            .tag(2)
        }
        .padding(.bottom)
        .accentColor(Color("AppCyan"))
    }

    private func addReadingToLibrary() {
        guard let selectedReading = selectedReading else { return }

        if libraryReadings.contains(where: { $0.content == selectedReading.content }) {
            toastMessage = "Reading is already in the library!"
            showToast = true // Show toast notification
            return
        }

        let newReadingEntity = ReadingEntity(context: viewContext)
        newReadingEntity.id = selectedReading.id
        newReadingEntity.title = selectedReading.title
        newReadingEntity.content = selectedReading.content

        do {
            try viewContext.save()
            toastMessage = "Reading added to library!"
            showToast = true // Show toast notification
        } catch {
            print("Failed to save reading: \(error.localizedDescription)")
        }
    }

    private func addReadingToLibrary(_ reading: Reading) {
        if libraryReadings.contains(where: { $0.content == reading.content }) {
            toastMessage = "Reading is already in the library!"
            showToast = true // Show toast notification
            return
        }

        let newReadingEntity = ReadingEntity(context: viewContext)
        newReadingEntity.id = reading.id
        newReadingEntity.title = reading.title
        newReadingEntity.content = reading.content

        do {
            try viewContext.save()
            toastMessage = "Reading added to library!"
            showToast = true // Show toast notification
        } catch {
            print("Failed to save reading: \(error.localizedDescription)")
        }
    }

    private func removeReadingFromLibrary(_ readingEntity: ReadingEntity) {
        viewContext.delete(readingEntity)

        do {
            try viewContext.save()
            toastMessage = "Reading removed from library!"
            showToast = true // Show toast notification
        } catch {
            print("Failed to remove reading: \(error.localizedDescription)")
        }
    }
}

struct ReadingDetailView: View {
    let reading: Reading
    let isFromLibrary: Bool
    let addToLibrary: (() -> Void)?
    let removeFromLibrary: (() -> Void)?

    var body: some View {
        VStack {
            Text(reading.title)
                .font(.title)
                .padding()

            ScrollView {
                Text(reading.content)
                    .font(.body)
                    .padding()
            }

            if !isFromLibrary {
                Button(action: {
                    addToLibrary?()
                }) {
                    Text("Add to Library")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Button(action: {
                    removeFromLibrary?()
                }) {
                    Text("Remove from Library")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}



class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "LibraryModel")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}


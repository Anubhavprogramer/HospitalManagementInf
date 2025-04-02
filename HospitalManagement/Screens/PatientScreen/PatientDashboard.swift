import SwiftUI

class HospitalManagementTestViewModel: ObservableObject {
    @Published var showUserProfile = false
}

// MARK: - Hide Back Button Modifier
struct HideBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
    }
}

extension View {
    func hideBackButton() -> some View {
        self.modifier(HideBackButtonModifier())
    }
}

// MARK: - Patient Dashboard View
struct PatientDashboard: View {
    private var viewModel: HospitalManagementViewModel = .init()
    @State private var patient: Patient
    @State private var showProfile = false
    @StateObject private var supabaseController = SupabaseController()
    @State private var departments: [Department] = []
    @State private var isLoadingDepartments = false
    @AppStorage("selectedHospitalId") private var selectedHospitalId: String = ""
    @State private var selectedTab = 0
    @State private var selectedHospital: Hospital?
    @State private var isHospitalSelectionPresented = false
    
    init(patient: Patient) {
        _patient = State(initialValue: patient)
        // Clear any pre-existing hospital selection
        UserDefaults.standard.removeObject(forKey: "selectedHospitalId")
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Home Tab
            NavigationView {
                HomeTabView(
                    selectedHospital: $selectedHospital,
                    departments: $departments
                )
                .navigationTitle("Hi, \(patient.fullname)")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showProfile = true
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(AppConfig.buttonColor)
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .sheet(isPresented: $showProfile) {
                ProfileView(patient: $patient)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // MARK: - Appointments Tab
            NavigationView {
                AppointmentsTabView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Appointments", systemImage: "calendar")
            }
            .tag(1)
            
            // MARK: - Records Tab
            NavigationView {
                RecordsTabView(selectedHospitalId: $selectedHospitalId)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Records", systemImage: "doc.text.fill")
            }
            .tag(2)
            
            // MARK: - Invoices Tab
            NavigationView {
                InvoiceListView(patientId: patient.id)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Invoices", systemImage: "doc.text.fill")
            }
            .tag(3)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            if !selectedHospitalId.isEmpty {
                loadDepartments()
                fetchSelectedHospital()
            }
        }
        .onChange(of: selectedHospitalId) { oldValue,newValue in
            if !newValue.isEmpty {
                loadDepartments()
                fetchSelectedHospital()
            } else {
                selectedHospital = nil
            }
        }
    }
    
    private func loadDepartments() {
        isLoadingDepartments = true
        departments = []
        
        guard let hospitalId = UUID(uuidString: selectedHospitalId) else {
            isLoadingDepartments = false
            return
        }
        
        Task {
            do {
                let fetchedDepartments = try await supabaseController.fetchHospitalDepartments(hospitalId: hospitalId)
                DispatchQueue.main.async {
                    departments = fetchedDepartments
                    isLoadingDepartments = false
                }
            } catch {
                print("Error loading departments: \(error)")
                DispatchQueue.main.async {
                    isLoadingDepartments = false
                }
            }
        }
    }
    
    private func fetchSelectedHospital() {
        guard let hospitalId = UUID(uuidString: selectedHospitalId) else {
            selectedHospital = nil
            return
        }
        
        Task {
            do {
                let hospitals = await supabaseController.fetchHospitals()
                if let hospital = hospitals.first(where: { $0.id == hospitalId }) {
                    DispatchQueue.main.async {
                        selectedHospital = hospital
                    }
                }
            } catch {
                print("Error fetching selected hospital: \(error)")
            }
        } 
    }
}

// MARK: - Preview
#Preview {
    PatientDashboard(patient: Patient(
        id: UUID(),
        fullName: "Tarun",
        gender: "male",
        dateOfBirth: Date(),
        contactNo: "1234567898",
        email: "tarun@gmail.com"
    ))
}

// MARK: - TextEditor Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder then: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            then()
                .opacity(shouldShow ? 1 : 0)
            
            self
        }
    }
    
    func placeholder(
        _ text: String,
        when shouldShow: Bool,
        alignment: Alignment = .leading
    ) -> some View {
        placeholder(when: shouldShow, alignment: alignment) {
            Text(text)
                .foregroundColor(.gray)
        }
    }
}


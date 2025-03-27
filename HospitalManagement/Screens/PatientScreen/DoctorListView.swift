import SwiftUI

struct DoctorListView: View {
    let doctors: [Doctor]
    @State private var selectedDoctor: Doctor?
    @State private var showAppointmentBookingModal = false
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: String?
    @StateObject private var supabaseController = SupabaseController()
    @State private var departmentDetails: [UUID: Department] = [:]
    @State private var isBookingAppointment = false
    @State private var bookingError: Error?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAppointmentType: AppointmentBookingView.AppointmentType?
    @State private var searchText = ""
    
    // Time slots for demonstration
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM", 
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    // Filtered doctors based on search
    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty {
            return doctors
        } else {
            return doctors.filter { doctor in
                let name = doctor.full_name.lowercased()
                let search = searchText.lowercased()
                
                // Filter by name only since 'specialization' doesn't exist
                return name.contains(search)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                TextField("Search by doctor name", text: $searchText)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                if filteredDoctors.isEmpty {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)
                        
                        if searchText.isEmpty {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No doctors available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No doctors match '\(searchText)'")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button("Clear Search") {
                                searchText = ""
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.mint)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    // Results Counter
                    if !searchText.isEmpty {
                        HStack {
                            Text("Found \(filteredDoctors.count) doctor(s)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    VStack(spacing: 15) {
                        ForEach(filteredDoctors) { doctor in
                            Button(action: {
                                selectedDoctor = doctor
                                showAppointmentBookingModal = true
                            }) {
                                doctorCard(doctor: doctor)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Select Doctor")
        .background(Color.mint.opacity(0.05))
        .task {
            // Fetch department details for each doctor
            for doctor in doctors {
                if let departmentId = doctor.department_id {
                    if let department = await supabaseController.fetchDepartmentDetails(departmentId: departmentId) {
                        departmentDetails[departmentId] = department
                    }
                }
            }
        }
        .sheet(isPresented: $showAppointmentBookingModal) {
            if let doctor = selectedDoctor {
                AppointmentBookingView(
                    doctor: doctor,
                    selectedDate: $selectedDate,
                    selectedTimeSlot: $selectedTimeSlot,
                    isBookingAppointment: $isBookingAppointment,
                    bookingError: $bookingError,
                    onBookAppointment: bookAppointment,
                    selectedAppointmentType: $selectedAppointmentType
                )
            }
        }
        .alert(isPresented: Binding.constant(bookingError != nil)) {
            Alert(
                title: Text("Booking Error"),
                message: Text(bookingError?.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    bookingError = nil
                }
            )
        }
    }
    
    private func bookAppointment() {
        guard let doctor = selectedDoctor,
              let appointmentType = selectedAppointmentType,
              let timeSlot = selectedTimeSlot else {
            return
        }
        
        isBookingAppointment = true
        
        Task {
            do {
                // TODO: Replace with actual appointment booking method from Supabase controller
                // Simulating an async booking process
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                // Prepare appointment details
                let appointmentDetails: [String: Any] = [
                    "doctorName": doctor.full_name,
                    "appointmentType": appointmentType.rawValue,
                    "date": selectedDate,
                    "timeSlot": timeSlot,
                    "timestamp": Date()
                ]
                
                // Save appointment details to UserDefaults
                var savedAppointments = UserDefaults.standard.array(forKey: "savedAppointments") as? [[String: Any]] ?? []
                savedAppointments.append(appointmentDetails)
                UserDefaults.standard.set(savedAppointments, forKey: "savedAppointments")
                
                // Reset and dismiss
                DispatchQueue.main.async {
                    isBookingAppointment = false
                    showAppointmentBookingModal = false
                    selectedTimeSlot = nil
                    selectedAppointmentType = nil
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isBookingAppointment = false
                    bookingError = error
                }
            }
        }
    }
    
    // MARK: - Doctor Card UI
    private func doctorCard(doctor: Doctor) -> some View {
        HStack(spacing: 15) {
            // Doctor avatar
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.mint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(doctor.full_name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 20) {
                    if let departmentId = doctor.department_id,
                       let department = departmentDetails[departmentId] {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(department.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "indianrupeesign")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(Int(department.fees))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                        }
                    }
                }
            }
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.mint)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .mint.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Appointment Booking Modal View
struct AppointmentBookingView: View {
    let doctor: Doctor
    @Binding var selectedDate: Date
    @Binding var selectedTimeSlot: String?
    @Binding var isBookingAppointment: Bool
    @Binding var bookingError: Error?
    var onBookAppointment: () -> Void
    @Binding var selectedAppointmentType: AppointmentType?
    
    // Appointment Types
    enum AppointmentType: String, CaseIterable {
        case consultation = "Consultation"
    }
    
    // Time slots for demonstration
    private let timeSlots = [
        "09:00 AM", "10:00 AM", "11:00 AM", 
        "02:00 PM", "03:00 PM", "04:00 PM"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Doctor Information Section
                Section(header: Text("Doctor Details")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.mint)
                        VStack(alignment: .leading) {
                            Text(doctor.full_name)
                                .font(.headline)
                            Text("Consultation Fee: ₹20")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Appointment Type Section
                Section(header: Text("Appointment Type")) {
                    VStack(spacing: 15) {
                        ForEach(AppointmentType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedAppointmentType = type
                            }) {
                                HStack {
                                    Image(systemName: "stethoscope")
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .fill(Color.mint)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(type.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Regular consultation with the doctor")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection indicator
                                    if selectedAppointmentType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.mint)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedAppointmentType == type ? 
                                              Color.mint.opacity(0.1) : 
                                              Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedAppointmentType == type ? 
                                                Color.mint : Color.gray.opacity(0.3), 
                                                lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // Date Selection Section
                Section(header: Text("Select Date")) {
                    DatePicker("Appointment Date", 
                               selection: $selectedDate, 
                               in: Date()..., 
                               displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                // Time Slot Selection Section
                Section(header: Text("Select Time Slot")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(timeSlots, id: \.self) { slot in
                                Button(action: {
                                    selectedTimeSlot = slot
                                }) {
                                    Text(slot)
                                        .padding(10)
                                        .background(
                                            selectedTimeSlot == slot ? 
                                            Color.mint : Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            selectedTimeSlot == slot ? 
                                            .white : .primary
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedTimeSlot == slot ? Color.mint : Color.gray, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarItems(
                trailing: Button(isBookingAppointment ? "Booking..." : "Book") {
                    onBookAppointment()
                }
                .disabled(
                    selectedTimeSlot == nil || 
                    selectedAppointmentType == nil || 
                    isBookingAppointment
                )
            )
        }
    }
}

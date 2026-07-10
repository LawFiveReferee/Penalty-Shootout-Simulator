// 11/05/25 8:56 am Build ready
// 11/05/25 7:23 am Layout Complete (add share button next)
// 7:35 am working; layout done
// optimizing 10-24-25 4:05pm
// adding circles to the results display. 10/24/25 3:40 pm
// starting horizontal view 10/24/25 1:15pm
// Works, stable, no scorecard 10/23/25 6:45 am

import SwiftUI

struct PenaltyRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let playerNumber: Int
    let scored: Bool
    
    init(playerNumber: Int, scored: Bool) {
        self.id = UUID()
        self.playerNumber = playerNumber
        self.scored = scored
    }
    
    func formattedPlayerNumber() -> String {
        if (playerNumber == 0) || (playerNumber == 100) {
            return "00"
        } else if playerNumber < 10 {
            return "\(playerNumber)"
        } else {
            return String(format: "%02d", playerNumber)
        }
    }
}

struct ContentView: View {
    @AppStorage("team1Name") private var team1Name = "Blue"
    @AppStorage("team2Name") private var team2Name = "Red"
    @AppStorage("team1Color") private var team1Color = "blue"
    @AppStorage("team2Color") private var team2Color = "red"
    @AppStorage("teamSize") private var teamSize = 11
    @AppStorage("team1Score") private var team1Score = 0
    @AppStorage("team2Score") private var team2Score = 0
    @AppStorage("team1Attempts") private var team1Attempts = 0
    @AppStorage("team2Attempts") private var team2Attempts = 0
    @AppStorage("currentRound") private var currentRound = 1
    @AppStorage("firstTeam") private var firstTeam = 1
    @AppStorage("lastRecordedTeam") private var lastRecordedTeam = 0
    @AppStorage("team1Penalties") private var team1PenaltiesData = Data()
    @AppStorage("team2Penalties") private var team2PenaltiesData = Data()
    
    @State private var showSettings = false
    @State private var selectedPlayerNumber = 0
    @State private var updateTrigger = 0
    @State private var team1PenaltiesArray: [PenaltyRecord] = []
    @State private var team2PenaltiesArray: [PenaltyRecord] = []
    @State private var winnerTeam: Int? = nil
    @State private var winningRound: Int = 1
    @State private var loserTurnsLeft: Int = 0
    @State private var team1TallyAtRound5: Int = 0
    @State private var team2TallyAtRound5: Int = 0
    @State private var shareText = ""
    @State private var showSummaryView = false
    @State private var showShareSheet = false
    
    var team1Penalties: [PenaltyRecord] {
        team1PenaltiesArray
    }
    
    var team2Penalties: [PenaltyRecord] {
        team2PenaltiesArray
    }
    
    let availableColors = [
        "black": Color.black,
        "blue": Color.blue,
        "gray": Color.gray,
        "green": Color.green,
        "lightblue": Color.cyan,
        "limegreen": Color.mint,
        "navy": Color.indigo,
        "orange": Color.orange,
        "pink": Color.pink,
        "purple": Color.purple,
        "red": Color.red,
        "white": Color.white,
        "yellow": Color.yellow
    ]
    
    func colorDisplayName(_ colorKey: String) -> String {
        switch colorKey {
        case "lightblue": return "Light Blue"
        case "limegreen": return "Lime-Green"
        case "navy": return "Navy"
        default: return colorKey.capitalized
        }
    }
    
    var currentTeamTurn: Int {
        let team1RoundAttempts = team1Attempts - ((currentRound - 1) * teamSize)
        let team2RoundAttempts = team2Attempts - ((currentRound - 1) * teamSize)
        let secondTeam = firstTeam == 1 ? 2 : 1
        let firstTeamRoundAttempts = firstTeam == 1 ? team1RoundAttempts : team2RoundAttempts
        let secondTeamRoundAttempts = secondTeam == 1 ? team1RoundAttempts : team2RoundAttempts
        
        if firstTeamRoundAttempts < teamSize {
            if secondTeamRoundAttempts < firstTeamRoundAttempts {
                return secondTeam
            } else {
                return firstTeam
            }
        } else if secondTeamRoundAttempts < teamSize {
            return secondTeam
        } else {
            return firstTeam
        }
    }

    var canSwitchTeamOrder: Bool {
        winnerTeam == nil && (team1Attempts + team2Attempts) < 2
    }

    var firstTeamName: String {
        firstTeam == 1 ? team1Name : team2Name
    }

    var secondTeamName: String {
        firstTeam == 1 ? team2Name : team1Name
    }
    
    var team1Tally: Int {
        let team1Goals = team1Score
        let team2Misses = team2PenaltiesArray.filter { !$0.scored }.count
        return team1Goals + team2Misses
    }
    
    var team2Tally: Int {
        let team2Goals = team2Score
        let team1Misses = team1PenaltiesArray.filter { !$0.scored }.count
        return team2Goals + team1Misses
    }
    
    var availablePlayerNumbers: [Int] {
        let allNumbers = Array(0...99)
        let currentTeamPenalties = currentTeamTurn == 1 ? team1PenaltiesArray : team2PenaltiesArray
        
        if currentTeamPenalties.count < teamSize {
            let used = Set(currentTeamPenalties.map { $0.playerNumber })
            let result = allNumbers.filter { !used.contains($0) }
            return result
        } else {
            let round1Players = Set(currentTeamPenalties.prefix(teamSize).map { $0.playerNumber })
            let roundIndex = currentTeamPenalties.count / teamSize
            let startOfCurrentRound = roundIndex * teamSize
            let currentRoundPenalties = currentTeamPenalties.dropFirst(startOfCurrentRound)
            let currentRoundPlayers = Set(currentRoundPenalties.map { $0.playerNumber })
            let result = round1Players.filter { !currentRoundPlayers.contains($0) }
            return Array(result).sorted()
        }
    }
    
    @ViewBuilder
    var landscapeContent: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 12) {
                if let winner = winnerTeam {
                    winnerAnnouncementView(winner: winner)
                        .padding(.vertical, 13)
                } else {
                    controlsView
                }
                
                Button(action: undoLastPenalty) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled((team1Attempts == 0) && (team2Attempts == 0))
                .opacity((team1Attempts == 0) && (team2Attempts == 0) ? 0.5 : 1.0)
                
                Button(action: resetShootout) {
                    Text("New Shoot-out")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .frame(width: UIScreen.main.bounds.width / 3)
            
            Divider()
            
            landscapeScorecardArea
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    @ViewBuilder
    var landscapeScorecardArea: some View {
        VStack(spacing: 2) {
            Text("Referee Scorecard")
                .font(.system(size: 16))
                .fontWeight(.semibold)
                .offset(x: -43)
            
            HStack(alignment: .top, spacing: -1) {
                ScorecardView(
                team1Name: team1Name,
                team2Name: team2Name,
                team1Penalties: team1Penalties,
                team2Penalties: team2Penalties,
                currentRound: currentRound,
                team1TallyAtRound5: team1TallyAtRound5,
                team2TallyAtRound5: team2TallyAtRound5
            )
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Rnd")
                        .font(.system(size: 15))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    Text(team1Name)
                        .font(.custom("Marker Felt", size: 16))
                        .foregroundStyle(.black)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    Text(team2Name)
                        .font(.custom("Marker Felt", size: 16))
                        .foregroundStyle(.black)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                }
                
                ForEach(12...24, id: \.self) { round in
                    HStack(spacing: 0) {
                        Text("\(round)")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        HStack(spacing: 0) {
                            Text((round <= team1Penalties.count) ? team1Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team1Penalties.count) ? (team1Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                        
                        HStack(spacing: 0) {
                            Text((round <= team2Penalties.count) ? team2Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team2Penalties.count) ? (team2Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                    }
                }
            }
        }
        .padding(.top, -2)
        .scaleEffect(0.81, anchor: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    @ViewBuilder
    var controlsView: some View {
        VStack(spacing: 8) {
            Text("Round \(Int(currentRound))")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(currentTeamTurn == 1 ? team1Name : team2Name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Player Number", selection: $selectedPlayerNumber) {
                ForEach(availablePlayerNumbers, id: \.self) { number in
                    Text(formatPlayerNumber(number))
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            
            VStack(spacing: 8) {
                Button(action: {
                    recordPenalty(team: currentTeamTurn, playerNumber: selectedPlayerNumber, scored: true)
                }) {
                    Text("Goal")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red), in: RoundedRectangle(cornerRadius: 10))
                }
                .sensoryFeedback(.success, trigger: team1Score + team2Score)
                
                Button(action: {
                    recordPenalty(team: currentTeamTurn, playerNumber: selectedPlayerNumber, scored: false)
                }) {
                    Text("Miss")
                        .font(.headline)
                        .foregroundStyle(currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background((currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red)).opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                }
                .sensoryFeedback(.error, trigger: team1Attempts + team2Attempts)
            }
        }
    }
    
    @ViewBuilder
    var portraitContent: some View {
        ScrollView {
            VStack(spacing: 15) {
                portraitTeamsHeader
                ruleOfSixCard
                penaltyHistory
                    .padding(.top, 5)
                
                if let winner = winnerTeam {
                    winnerAnnouncementView(winner: winner)
                        .padding(.horizontal)
                        .padding(.top, 8)
                } else {
                    portraitInputControls
                }
                
                portraitActionButtons
                scorecard
            }
        }
    }
    
    @ViewBuilder
    var portraitTeamsHeader: some View {
        HStack(spacing: 18) {
            TeamView(
                name: team1Name,
                color: availableColors[team1Color] ?? .blue,
                score: team1Score,
                isCurrentTurn: currentTeamTurn == 1
            )
            
            VStack(spacing: 3) {
                Text("vs")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .offset(y: -2)

                switchTeamOrderButton
            }
            .frame(width: 92)
            
            TeamView(
                name: team2Name,
                color: availableColors[team2Color] ?? .red,
                score: team2Score,
                isCurrentTurn: currentTeamTurn == 2
            )
        }
        .padding(.horizontal)
        .padding(.top, 14)
        .padding(.bottom, 7)
    }

    @ViewBuilder
    var switchTeamOrderButton: some View {
        Button(action: switchTeamOrder) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(canSwitchTeamOrder ? .blue : .secondary)
                .frame(width: 24, height: 16)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color(.systemGray6), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSwitchTeamOrder)
        .opacity(canSwitchTeamOrder ? 1.0 : 0.55)
        .accessibilityLabel("Switch shooting order")
        .accessibilityHint("\(firstTeamName) shoots first, \(secondTeamName) shoots second")
    }
    
    @ViewBuilder
    var ruleOfSixCard: some View {
        VStack(spacing: 12) {
            Text("Rule of Six")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 40) {
                Text("\(currentRound <= 5 ? team1Tally : team1TallyAtRound5)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(availableColors[team1Color] ?? .blue)
                
                Text("\(currentRound <= 5 ? team2Tally : team2TallyAtRound5)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(availableColors[team2Color] ?? .red)
            }
            
            if currentRound <= 5 {
                VStack(spacing: 2) {
                    Text("Goals + opponent misses")
                        .font(.callout)
                        .foregroundStyle(.primary)
                    Text("First to 6, in first five rounds, wins")
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            } else {
                VStack(spacing: 2) {
                    Text("Round-by-round")
                        .font(.callout)
                        .foregroundStyle(.primary)
                    Text("Tallies frozen at Round 5")
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .opacity(currentRound <= 5 ? 1.0 : 0.5)
        .padding(.horizontal)
        .padding(.top, 7)
        .padding(.bottom, 17)
    }
    
    @ViewBuilder
    var penaltyHistory: some View {
        PenaltyHistoryView(
            team1Name: team1Name,
            team2Name: team2Name,
            team1Color: availableColors[team1Color] ?? .blue,
            team2Color: availableColors[team2Color] ?? .red,
            team1Penalties: team1Penalties,
            team2Penalties: team2Penalties
        )
        .id(updateTrigger)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var portraitInputControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("Round \(Int(currentRound)): \(currentTeamTurn == 1 ? team1Name : team2Name) #:")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Picker("Player Number", selection: $selectedPlayerNumber) {
                    ForEach(availablePlayerNumbers, id: \.self) { number in
                        Text(formatPlayerNumber(number))
                            .tag(number)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 120)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    recordPenalty(team: currentTeamTurn, playerNumber: selectedPlayerNumber, scored: true)
                }) {
                    Text("Goal")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 90)
                        .padding(.vertical, 17)
                        .background(currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red), in: RoundedRectangle(cornerRadius: 12))
                }
                .sensoryFeedback(.success, trigger: team1Score + team2Score)
                
                Button(action: {
                    recordPenalty(team: currentTeamTurn, playerNumber: selectedPlayerNumber, scored: false)
                }) {
                    Text("Miss")
                        .font(.headline)
                        .foregroundStyle(currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red))
                        .frame(width: 90)
                        .padding(.vertical, 17)
                        .background((currentTeamTurn == 1 ? (availableColors[team1Color] ?? .blue) : (availableColors[team2Color] ?? .red)).opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .sensoryFeedback(.error, trigger: team1Attempts + team2Attempts)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var portraitActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: undoLastPenalty) {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled((team1Attempts == 0) && (team2Attempts == 0))
            .opacity((team1Attempts == 0) && (team2Attempts == 0) ? 0.5 : 1.0)
            
            Button(action: resetShootout) {
                Text("New Shoot-out")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
        .padding(.top, 18)
        .padding(.bottom, -10)
    }
    
    @ViewBuilder
    var scorecard: some View {
        VStack(spacing: 4) {
            Text("Referee Scorecard")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScorecardView(
                team1Name: team1Name,
                team2Name: team2Name,
                team1Penalties: team1Penalties,
                team2Penalties: team2Penalties,
                currentRound: currentRound,
                team1TallyAtRound5: team1TallyAtRound5,
                team2TallyAtRound5: team2TallyAtRound5
            )
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    @ViewBuilder
    func winnerAnnouncementView(winner: Int) -> some View {
        let winnerName = winner == 1 ? team1Name : team2Name
        let loserName = winner == 1 ? team2Name : team1Name
        let winnerScore = winner == 1 ? team1Score : team2Score
        let loserScore = winner == 1 ? team2Score : team1Score
        let wonByRuleOfSix = winningRound <= 5
        
        VStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(winnerName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Wins!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(winnerScore) - \(loserScore)")
                .font(.title3)
            
            if wonByRuleOfSix {
                let goalLead = winnerScore - loserScore
                
                Text("\(winnerName) has a \(goalLead) goal lead and \(loserName) has only \(loserTurnsLeft) turn\(loserTurnsLeft == 1 ? "" : "s") left")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            
            Text("Tap to start a new shoot-out")
                .font(.system(size: 16))
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.yellow.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow, lineWidth: 2)
        )
        .onTapGesture {
            resetShootout()
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                VStack(spacing: 0) {
                    if !isLandscape {
                        HStack {
                            Text("Penalty Shoot-out")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(appVersionDisplay)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.top, 5)
                            
                            Spacer()
                            
                            Button(action: {
                                shareText = generateShareText()
                                showSummaryView = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        
                        Divider()
                    }
                    
                    if isLandscape {
                        landscapeContent
                    } else {
                        portraitContent
                    }
                }
            }
            .onAppear {
                resetShootout()
                
                if let decoded1 = try? JSONDecoder().decode([PenaltyRecord].self, from: team1PenaltiesData) {
                    team1PenaltiesArray = decoded1
                }
                if let decoded2 = try? JSONDecoder().decode([PenaltyRecord].self, from: team2PenaltiesData) {
                    team2PenaltiesArray = decoded2
                }
                if !availablePlayerNumbers.isEmpty, !availablePlayerNumbers.contains(selectedPlayerNumber) {
                    let defaultIndex = min(2, availablePlayerNumbers.count - 1)
                    selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
                }
            }
            .onChange(of: currentTeamTurn) { oldValue, newValue in
                if !availablePlayerNumbers.isEmpty {
                    let defaultIndex = min(2, availablePlayerNumbers.count - 1)
                    selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
                }
            }
            .onChange(of: team1PenaltiesArray) { oldValue, newValue in
                if currentTeamTurn == 1, !availablePlayerNumbers.isEmpty, !availablePlayerNumbers.contains(selectedPlayerNumber) {
                    let defaultIndex = min(2, availablePlayerNumbers.count - 1)
                    selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
                }
            }
            .onChange(of: team2PenaltiesArray) { oldValue, newValue in
                if currentTeamTurn == 2, !availablePlayerNumbers.isEmpty, !availablePlayerNumbers.contains(selectedPlayerNumber) {
                    let defaultIndex = min(2, availablePlayerNumbers.count - 1)
                    selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    team1Name: $team1Name,
                    team2Name: $team2Name,
                    team1Color: $team1Color,
                    team2Color: $team2Color,
                    teamSize: $teamSize,
                    availableColors: availableColors
                )
            }
            .sheet(isPresented: $showSummaryView) {
                SummaryView(summaryText: shareText, showShareSheet: $showShareSheet)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    var appVersionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.5.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "3"
        return "v\(version) (\(build))"
    }
    
    func generateShareText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timestamp = formatter.string(from: Date())
        
        var text = "PENALTY SHOOT-OUT SUMMARY\n"
        text += "\(timestamp)\n"
        text += "\(team1Name) vs \(team2Name)\n"
        text += String(repeating: "=", count: 33) + "\n\n"
        
        // Check if shootout hasn't started
        if team1Penalties.count == 0 && team2Penalties.count == 0 {
            text += "Ready to start shoot-out\n\n"
            text += String(repeating: "=", count: 33) + "\n"
            text += "STATUS: Awaiting first penalty\n"
            return text
        }
        
        let maxRounds = max(team1Penalties.count, team2Penalties.count)
        
        for round in 1...maxRounds {
            if round == 1 {
                text += "(Rule of 6 tally = team's goals + opponent's misses)\n\n"
            }
            
            if round == 6 {
                text += "(Rule of 6 does not apply after fifth round)\n\n"
            }
            
            text += String(repeating: "-", count: 33) + "\n"
            text += "ROUND \(round)\n"
            
            if round <= team1Penalties.count {
                let penalty = team1Penalties[round - 1]
                text += "\(team1Name) #\(penalty.formattedPlayerNumber()): \(penalty.scored ? "GOAL" : "MISS")\n"
            }
            
            if round <= team2Penalties.count {
                let penalty = team2Penalties[round - 1]
                text += "\(team2Name) #\(penalty.formattedPlayerNumber()): \(penalty.scored ? "GOAL" : "MISS")\n"
            }
            
            let team1GoalsSoFar = team1Penalties.prefix(round).filter { $0.scored }.count
            let team2GoalsSoFar = team2Penalties.prefix(round).filter { $0.scored }.count
            
            text += "\nScore: \(team1Name) \(team1GoalsSoFar) - \(team2Name) \(team2GoalsSoFar)\n"
            
            if round <= 5 {
                let team1MissesSoFar = team1Penalties.prefix(round).filter { !$0.scored }.count
                let team2MissesSoFar = team2Penalties.prefix(round).filter { !$0.scored }.count
                let team1Tally = team1GoalsSoFar + team2MissesSoFar
                let team2Tally = team2GoalsSoFar + team1MissesSoFar
                
                text += "Rule of 6 Tally: \(team1Name) \(team1Tally) - \(team2Name) \(team2Tally)\n"
                
                let team1Attempts = min(round, team1Penalties.count)
                let team2Attempts = min(round, team2Penalties.count)
                let team1Remaining = 5 - team1Attempts
                let team2Remaining = 5 - team2Attempts
                
                if team1Tally >= 6 && team2Tally < 6 {
                    text += "\nINSURMOUNTABLE LEAD: \(team1Name) has reached 6 on Rule of 6\n"
                    let goalDiff = team1GoalsSoFar - team2GoalsSoFar
                    text += "\(team2Name) is behind by \(goalDiff) goal\(goalDiff == 1 ? "" : "s") with only \(team2Remaining) turn\(team2Remaining == 1 ? "" : "s") remaining\n"
                } else if team2Tally >= 6 && team1Tally < 6 {
                    text += "\nINSURMOUNTABLE LEAD: \(team2Name) has reached 6 on Rule of 6\n"
                    let goalDiff = team2GoalsSoFar - team1GoalsSoFar
                    text += "\(team1Name) is behind by \(goalDiff) goal\(goalDiff == 1 ? "" : "s") with only \(team1Remaining) turn\(team1Remaining == 1 ? "" : "s") remaining\n"
                } else {
                    let goalDiff = abs(team1GoalsSoFar - team2GoalsSoFar)
                    if goalDiff > 0 {
                        let leader = team1GoalsSoFar > team2GoalsSoFar ? team1Name : team2Name
                        text += "\n\(leader) leads by \(goalDiff) goal\(goalDiff == 1 ? "" : "s")\n"
                    } else {
                        text += "\nTied\n"
                    }
                }
            } else {
                let team1AttemptsInRound = min(round, team1Penalties.count)
                let team2AttemptsInRound = min(round, team2Penalties.count)
                
                if team1GoalsSoFar == team2GoalsSoFar {
                    text += "Status: Tied - sudden death continues\n"
                } else if (team1AttemptsInRound == round) && (team2AttemptsInRound == round) {
                    let winner = team1GoalsSoFar > team2GoalsSoFar ? team1Name : team2Name
                    text += "Status: \(winner) wins after Round \(round)\n"
                }
            }
            
            text += "\n"
        }
        
        text += String(repeating: "=", count: 33) + "\n"
        
        if let winner = winnerTeam {
            let winnerName = winner == 1 ? team1Name : team2Name
            let winnerScore = winner == 1 ? team1Score : team2Score
            let loserScore = winner == 1 ? team2Score : team1Score
            text += "FINAL RESULT\n"
            text += "\(winnerName) WINS \(winnerScore)-\(loserScore)\n"
        } else {
            text += "CURRENT STATUS\n"
            text += "\(team1Name) \(team1Score) - \(team2Name) \(team2Score)\n"
        }
        
        return text
    }
    
    func formatPlayerNumber(_ number: Int) -> String {
        if (number == 0) || (number == 100) {
            return "00"
        } else if number < 10 {
            return "\(number)"
        } else {
            return String(format: "%02d", number)
        }
    }
    
    func recordPenalty(team: Int, playerNumber: Int, scored: Bool) {
        let penalty = PenaltyRecord(playerNumber: playerNumber, scored: scored)
        
        if team == 1 {
            team1PenaltiesArray.append(penalty)
            if let encoded = try? JSONEncoder().encode(team1PenaltiesArray) {
                team1PenaltiesData = encoded
            }
            team1Attempts += 1
            if scored {
                team1Score += 1
            }
        } else {
            team2PenaltiesArray.append(penalty)
            if let encoded = try? JSONEncoder().encode(team2PenaltiesArray) {
                team2PenaltiesData = encoded
            }
            team2Attempts += 1
            if scored {
                team2Score += 1
            }
        }

        lastRecordedTeam = team
        
        checkRoundAdvance()
        checkRuleOfSix()
        checkPostRound5Winner()
        
        if !availablePlayerNumbers.isEmpty {
            let defaultIndex = min(2, availablePlayerNumbers.count - 1)
            selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
        }
        
        updateTrigger += 1
    }

    func switchTeamOrder() {
        guard canSwitchTeamOrder else {
            return
        }

        firstTeam = firstTeam == 1 ? 2 : 1

        if !availablePlayerNumbers.isEmpty {
            let defaultIndex = min(2, availablePlayerNumbers.count - 1)
            selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
        }

        updateTrigger += 1
    }
    
    func checkRuleOfSix() {
        if currentRound <= 5 && team1Attempts <= 5 && team2Attempts <= 5 {
            if (team1Tally >= 6) && (team2Tally < 6) {
                winnerTeam = 1
                winningRound = currentRound
                loserTurnsLeft = 5 - team2Attempts
            } else if (team2Tally >= 6) && (team1Tally < 6) {
                winnerTeam = 2
                winningRound = currentRound
                loserTurnsLeft = 5 - team1Attempts
            }
        }
    }
    
    func checkPostRound5Winner() {
        if currentRound > 5 {
            let minAttempts = min(team1Attempts, team2Attempts)
            
            if team1Attempts == minAttempts && team2Attempts == minAttempts {
                if team1Score > team2Score {
                    winnerTeam = 1
                    winningRound = currentRound
                } else if team2Score > team1Score {
                    winnerTeam = 2
                    winningRound = currentRound
                }
            }
        }
    }
    
    func checkRoundAdvance() {
        let minAttempts = min(team1Attempts, team2Attempts)
        let newRound = minAttempts + 1
        
        if newRound != currentRound {
            if currentRound == 5 && newRound == 6 {
                team1TallyAtRound5 = team1Tally
                team2TallyAtRound5 = team2Tally
            }
            currentRound = newRound
            updateTrigger += 1
        }
    }
    
    func undoLastPenalty() {
        let teamToUndo = lastRecordedTeam == 0 ? inferredLastPenaltyTeam : lastRecordedTeam

        if teamToUndo == 1 {
            if !team1PenaltiesArray.isEmpty {
                let lastPenalty = team1PenaltiesArray.removeLast()
                if let encoded = try? JSONEncoder().encode(team1PenaltiesArray) {
                    team1PenaltiesData = encoded
                }
                team1Attempts -= 1
                if lastPenalty.scored {
                    team1Score -= 1
                }
            }
        } else if teamToUndo == 2 {
            if !team2PenaltiesArray.isEmpty {
                let lastPenalty = team2PenaltiesArray.removeLast()
                if let encoded = try? JSONEncoder().encode(team2PenaltiesArray) {
                    team2PenaltiesData = encoded
                }
                team2Attempts -= 1
                if lastPenalty.scored {
                    team2Score -= 1
                }
            }
        }

        lastRecordedTeam = inferredLastPenaltyTeam
        
        let minAttempts = min(team1Attempts, team2Attempts)
        currentRound = max(1, minAttempts + 1)
        
        if minAttempts < 5 {
            team1TallyAtRound5 = 0
            team2TallyAtRound5 = 0
        } else if minAttempts == 5 {
            team1TallyAtRound5 = team1Tally
            team2TallyAtRound5 = team2Tally
        }
        
        winnerTeam = nil
        
        updateTrigger += 1
    }

    var inferredLastPenaltyTeam: Int {
        if team1Attempts == 0 && team2Attempts == 0 {
            return 0
        }

        if team1Attempts > team2Attempts {
            return 1
        } else if team2Attempts > team1Attempts {
            return 2
        } else {
            return firstTeam == 1 ? 2 : 1
        }
    }
    
    func resetShootout() {
        team1Score = 0
        team2Score = 0
        team1Attempts = 0
        team2Attempts = 0
        currentRound = 1
        team1PenaltiesData = Data()
        team2PenaltiesData = Data()
        team1PenaltiesArray = []
        team2PenaltiesArray = []
        winnerTeam = nil
        loserTurnsLeft = 0
        lastRecordedTeam = 0
        team1TallyAtRound5 = 0
        team2TallyAtRound5 = 0
        updateTrigger += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !availablePlayerNumbers.isEmpty {
                let defaultIndex = min(2, availablePlayerNumbers.count - 1)
                selectedPlayerNumber = availablePlayerNumbers[defaultIndex]
            }
        }
    }
}

struct PenaltyHistoryView: View {
    let team1Name: String
    let team2Name: String
    let team1Color: Color
    let team2Color: Color
    let team1Penalties: [PenaltyRecord]
    let team2Penalties: [PenaltyRecord]
    
    func rowsForTeam(penalties: [PenaltyRecord]) -> [[PenaltyRecord]] {
        var rows: [[PenaltyRecord]] = []
        var currentRow: [PenaltyRecord] = []
        
        for penalty in penalties {
            currentRow.append(penalty)
            if currentRow.count == 5 {
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text(team1Name)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundStyle(team1Color)
                    .frame(width: 180, alignment: .center)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1)
                
                Text(team2Name)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundStyle(team2Color)
                    .frame(width: 180, alignment: .center)
            }
            
            VStack(spacing: 4) {
                let team1Rows = rowsForTeam(penalties: team1Penalties)
                let team2Rows = rowsForTeam(penalties: team2Penalties)
                
                HStack(spacing: 4) {
                    HStack(spacing: 4) {
                        let firstRoundPenalties = team1Rows.first ?? []
                        ForEach(0..<5, id: \.self) { index in
                            if index < firstRoundPenalties.count {
                                PenaltyCell(penalty: firstRoundPenalties[index], color: team1Color)
                            } else {
                                EmptyPenaltyCell(color: team1Color)
                            }
                        }
                    }
                    .frame(width: 180, alignment: .leading)
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1)
                        .padding(.horizontal, 2)
                    
                    HStack(spacing: 4) {
                        let firstRoundPenalties = team2Rows.first ?? []
                        ForEach(0..<5, id: \.self) { index in
                            if index < firstRoundPenalties.count {
                                PenaltyCell(penalty: firstRoundPenalties[index], color: team2Color)
                            } else {
                                EmptyPenaltyCell(color: team2Color)
                            }
                        }
                    }
                    .frame(width: 180, alignment: .leading)
                }
                
                if team1Rows.count > 1 || team2Rows.count > 1 {
                    let maxRounds = max(team1Rows.count, team2Rows.count)
                    ForEach(1..<maxRounds, id: \.self) { roundIndex in
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                if roundIndex < team1Rows.count {
                                    ForEach(team1Rows[roundIndex]) { penalty in
                                        PenaltyCell(penalty: penalty, color: team1Color)
                                    }
                                }
                            }
                            .frame(width: 180, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 1)
                                .padding(.horizontal, 2)
                            
                            HStack(spacing: 4) {
                                if roundIndex < team2Rows.count {
                                    ForEach(team2Rows[roundIndex]) { penalty in
                                        PenaltyCell(penalty: penalty, color: team2Color)
                                    }
                                }
                            }
                            .frame(width: 180, alignment: .leading)
                        }
                    }
                }
            }
            .frame(minHeight: 40)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .frame(width: 370)
    }
}

struct PenaltyCell: View {
    let penalty: PenaltyRecord
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(penalty.scored ? color : color.opacity(0.2))
                .frame(width: 32, height: 32)
            
            VStack(spacing: 0) {
                Text(penalty.formattedPlayerNumber())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(penalty.scored ? .white : color)
                
                Image(systemName: penalty.scored ? "checkmark" : "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(penalty.scored ? .white : color)
            }
        }
    }
}

struct EmptyPenaltyCell: View {
    let color: Color
    
    var body: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 1)
            .frame(width: 32, height: 32)
    }
}

struct TeamView: View {
    let name: String
    let color: Color
    let score: Int
    let isCurrentTurn: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(score)")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(color)
                .opacity(isCurrentTurn ? 1.0 : 0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TallyGroup: View {
    let marks: Int
    
    var body: some View {
        ZStack {
            HStack(spacing: 3) {
                ForEach(0..<min(marks, 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 16)
                }
            }
            
            if marks == 5 {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 16, height: 2)
                    .rotationEffect(.degrees(-25))
            }
        }
        .frame(width: 16, height: 16)
    }
}

struct TallyMarks: View {
    let count: Int
    
    var body: some View {
        let groupCount = max(1, (count + 4) / 5)
        
        HStack(spacing: 6) {
            ForEach(0..<groupCount, id: \.self) { index in
                let marksInGroup = min(5, max(0, count - (index * 5)))
                if marksInGroup > 0 {
                    TallyGroup(marks: marksInGroup)
                }
            }
        }
    }
}

struct ScorecardView: View {
    let team1Name: String
    let team2Name: String
    let team1Penalties: [PenaltyRecord]
    let team2Penalties: [PenaltyRecord]
    let currentRound: Int
    let team1TallyAtRound5: Int
    let team2TallyAtRound5: Int
    
    var team1CurrentTally: Int {
        let goals = team1Penalties.filter { $0.scored }.count
        let opponentMisses = team2Penalties.filter { !$0.scored }.count
        return goals + opponentMisses
    }
    
    var team2CurrentTally: Int {
        let goals = team2Penalties.filter { $0.scored }.count
        let opponentMisses = team1Penalties.filter { !$0.scored }.count
        return goals + opponentMisses
    }
    
    var displayTeam1Tally: Int {
        currentRound <= 5 ? team1CurrentTally : team1TallyAtRound5
    }
    
    var displayTeam2Tally: Int {
        currentRound <= 5 ? team2CurrentTally : team2TallyAtRound5
    }
    
    var team1Score: Int {
        team1Penalties.filter { $0.scored }.count
    }
    
    var team2Score: Int {
        team2Penalties.filter { $0.scored }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Rnd")
                        .font(.system(size: 15))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    Text(team1Name)
                        .font(.custom("Marker Felt", size: 17))
                        .foregroundStyle(.black)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    Text(team2Name)
                        .font(.custom("Marker Felt", size: 17))
                        .foregroundStyle(.black)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                }
                
                ForEach(1...5, id: \.self) { round in
                    HStack(spacing: 0) {
                        Text("\(round)")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        HStack(spacing: 0) {
                            Text((round <= team1Penalties.count) ? team1Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team1Penalties.count) ? (team1Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                        
                        HStack(spacing: 0) {
                            Text((round <= team2Penalties.count) ? team2Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team2Penalties.count) ? (team2Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    Text("")
                        .font(.system(size: 15))
                        .frame(width: 50, height: 58)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    HStack(spacing: 0) {
                        Text("R-6 Tally")
                            .font(.system(size: 16))
                            .foregroundStyle(.black)
                            .strikethrough(currentRound > 5)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: 55, height: 58)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        TallyMarks(count: displayTeam1Tally)
                            .strikethrough(currentRound > 5)
                            .frame(width: 55, height: 58)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                    }
                    
                    HStack(spacing: 0) {
                        Text("R-6 Tally")
                            .font(.system(size: 16))
                            .foregroundStyle(.black)
                            .strikethrough(currentRound > 5)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: 55, height: 58)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        TallyMarks(count: displayTeam2Tally)
                            .strikethrough(currentRound > 5)
                            .frame(width: 55, height: 58)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                    }
                }
            }
            
            VStack(spacing: 0) {
                ForEach(6...11, id: \.self) { round in
                    HStack(spacing: 0) {
                        Text("\(round)")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        HStack(spacing: 0) {
                            Text((round <= team1Penalties.count) ? team1Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team1Penalties.count) ? (team1Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                        
                        HStack(spacing: 0) {
                            Text((round <= team2Penalties.count) ? team2Penalties[round - 1].formattedPlayerNumber() : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            Text((round <= team2Penalties.count) ? (team2Penalties[round - 1].scored ? "1" : "0") : "")
                                .font(.custom("Marker Felt", size: 17))
                                .foregroundStyle(.black)
                                .frame(width: 55, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    Text("Goals")
                        .font(.system(size: 15))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    TallyMarks(count: team1Score)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                    
                    TallyMarks(count: team2Score)
                        .frame(width: 110, height: 29)
                        .background(Color.white)
                        .border(Color.black, width: 1)
                }
            }
            
            if currentRound > 11 {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Rnd")
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        Text(team1Name)
                            .font(.custom("Marker Felt", size: 17))
                            .foregroundStyle(.black)
                            .frame(width: 110, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                        
                        Text(team2Name)
                            .font(.custom("Marker Felt", size: 17))
                            .foregroundStyle(.black)
                            .frame(width: 110, height: 29)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                    }
                    
                    ForEach(12...24, id: \.self) { round in
                        HStack(spacing: 0) {
                            Text("\(round)")
                                .font(.system(size: 15))
                                .foregroundStyle(.black)
                                .frame(width: 50, height: 29)
                                .background(Color.white)
                                .border(Color.black, width: 1)
                            
                            HStack(spacing: 0) {
                                Text((round <= team1Penalties.count) ? team1Penalties[round - 1].formattedPlayerNumber() : "")
                                    .font(.custom("Marker Felt", size: 17))
                                    .foregroundStyle(.black)
                                    .frame(width: 55, height: 29)
                                    .background(Color.white)
                                    .border(Color.black, width: 1)
                                
                                Text((round <= team1Penalties.count) ? (team1Penalties[round - 1].scored ? "1" : "0") : "")
                                    .font(.custom("Marker Felt", size: 17))
                                    .foregroundStyle(.black)
                                    .frame(width: 55, height: 29)
                                    .background(Color.white)
                                    .border(Color.black, width: 1)
                            }
                            
                            HStack(spacing: 0) {
                                Text((round <= team2Penalties.count) ? team2Penalties[round - 1].formattedPlayerNumber() : "")
                                    .font(.custom("Marker Felt", size: 17))
                                    .foregroundStyle(.black)
                                    .frame(width: 55, height: 29)
                                    .background(Color.white)
                                    .border(Color.black, width: 1)
                                
                                Text((round <= team2Penalties.count) ? (team2Penalties[round - 1].scored ? "1" : "0") : "")
                                    .font(.custom("Marker Felt", size: 17))
                                    .foregroundStyle(.black)
                                    .frame(width: 55, height: 29)
                                    .background(Color.white)
                                    .border(Color.black, width: 1)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

struct SettingsView: View {
    @Binding var team1Name: String
    @Binding var team2Name: String
    @Binding var team1Color: String
    @Binding var team2Color: String
    @Binding var teamSize: Int
    let availableColors: [String: Color]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showCustomColorAlert = false
    @State private var customColorTeam = 1
    @State private var showAbout = false
    
    var colorKeys: [String] {
        ["black", "blue", "gray", "green", "lightblue", "limegreen", "navy", "orange", "pink", "purple", "red", "white", "yellow"]
    }
    
    func colorDisplayName(_ colorKey: String) -> String {
        switch colorKey {
        case "lightblue": return "Light Blue"
        case "limegreen": return "Lime-Green"
        case "navy": return "Navy"
        default: return colorKey.capitalized
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Team Size")
                            .font(.headline)
                        
                        Picker("Team Size", selection: $teamSize) {
                            ForEach(5...11, id: \.self) { size in
                                Text("\(size) players").tag(size)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teams")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            VStack(spacing: 12) {
                                TextField("Team Name", text: $team1Name)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.center)
                                
                                Menu {
                                    ForEach(colorKeys.filter { $0 != team2Color }, id: \.self) { key in
                                        Button(action: {
                                            team1Color = key
                                            team1Name = colorDisplayName(key)
                                        }) {
                                            HStack {
                                                Circle()
                                                    .fill(availableColors[key] ?? .gray)
                                                    .frame(width: 16, height: 16)
                                                Text(colorDisplayName(key))
                                            }
                                        }
                                    }
                                    
                                    Button(action: {
                                        customColorTeam = 1
                                        showCustomColorAlert = true
                                    }) {
                                        HStack {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 1)
                                                .frame(width: 16, height: 16)
                                            Text("Other")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(availableColors[team1Color] ?? .gray)
                                            .frame(width: 20, height: 20)
                                        Text("Color")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text("vs")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 12) {
                                TextField("Team Name", text: $team2Name)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.center)
                                
                                Menu {
                                    ForEach(colorKeys.filter { $0 != team1Color }, id: \.self) { key in
                                        Button(action: {
                                            team2Color = key
                                            team2Name = colorDisplayName(key)
                                        }) {
                                            HStack {
                                                Circle()
                                                    .fill(availableColors[key] ?? .gray)
                                                    .frame(width: 16, height: 16)
                                                Text(colorDisplayName(key))
                                            }
                                        }
                                    }
                                    
                                    Button(action: {
                                        customColorTeam = 2
                                        showCustomColorAlert = true
                                    }) {
                                        HStack {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 1)
                                                .frame(width: 16, height: 16)
                                            Text("Other")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(availableColors[team2Color] ?? .gray)
                                            .frame(width: 20, height: 20)
                                        Text("Color")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Penalty Shoot-out Scorecard PDFs")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        Text("Printable referee wallet scorecards for use during games.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Link(destination: URL(string: "https://www.law5ref.com/downloads/Penalty-Shoot-out-Scorecard.pdf")!) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                    Text("Download Wallet Scorecard")
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.blue)
                            }
                            
                            Text("PDF file with 4x6\" Penalty Shoot-out Scorecard for referee's wallet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 10)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Link(destination: URL(string: "https://www.law5ref.com/downloads/Two-Penalty-Shoot-out-Scorecards.pdf")!) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Download Letter Size Scorecards")
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.blue)
                            }
                            
                            Text("PDF file with 2 4x6\" Penalty Shoot-out Scorecards, with instructions, for printing on letter-size paper.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 10)
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("About") {
                        showAbout = true
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Custom Color", isPresented: $showCustomColorAlert) {
                Button("OK") {}
            } message: {
                Text("Custom color input coming soon!")
            }
        }
    }
}

struct SummaryView: View {
    let summaryText: String
    @Binding var showShareSheet: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(summaryText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Shoot-out Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showShare = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: [summaryText])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Penalty Shoot-out Simulator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .fontWeight(.bold)
                    
                    Text("This app is designed to help referees, coaches, and soccer enthusiasts learn to accurately track soccer penalty shoot-outs when a match ends in a tie.")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Features:")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Track penalty shoot-outs in real time")
                            Text("• Customizable team colors and names")
                            Text("• Select player numbers for each turn")
                            Text("• Professional referee scorecard view and demonstration")
                            Text("• Rule-of-Six automatic calculation")
                            Text("• Number of eligible players (5-11)")
                            Text("• Undo capability for error correction")
                            Text("• Share results for match reports")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Link(destination: URL(string: "https://www.law5ref.com/privacy.html")!) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundStyle(.blue)
                        }
                        
                        Link(destination: URL(string: "mailto:support@law5ref.com")!) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Support")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundStyle(.blue)
                        }
                        
                        Link(destination: URL(string: "https://www.law5ref.com/penalty-faq.html")!) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Rule-of-6 Documentation and FAQs")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("Built for iOS with SwiftUI technology.")
                        .italic()
                    
                    Link(destination: URL(string: "https://www.bitrig.app")!) {
                        Text("Swift code generated with Bitrig AI.")
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

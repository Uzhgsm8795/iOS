//
//  SubscriptionRestoreView.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SwiftUI
import DesignResourcesKit
import Core

#if SUBSCRIPTION
@available(iOS 15.0, *)
struct SubscriptionRestoreView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.rootPresentationMode) private var rootPresentationMode: Binding<RootPresentationMode>
    @StateObject var viewModel = SubscriptionRestoreViewModel()
    @State private var expandedItemId: Int = 0
    @State private var isAlertVisible = false
    @State private var isActive: Bool = false
    var onDismissStack: (() -> Void)?
    
    private enum Constants {
        static let heroImage = "ManageSubscriptionHero"
        static let appleIDIcon = "Platform-Apple-16"
        static let emailIcon = "Email-16"
        static let headerLineSpacing = 10.0
        static let viewStackSpacing = 20.0
        static let footerLineSpacing = 7.0
        static let openIndicator = "chevron.up"
        static let closedIndicator = "chevron.down"
        static let cornerRadius = 12.0
        static let buttonCornerRadius = 8.0
        static let buttonInsets = EdgeInsets(top: 10.0, leading: 16.0, bottom: 10.0, trailing: 16.0)
        static let cellLineSpacing = 12.0
        static let cellPadding = 20.0
        static let headerPadding = EdgeInsets(top: 16.0, leading: 30.0, bottom: 0, trailing: 30.0)
        static let viewPadding: CGFloat = 18.0
        static let listPadding = EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30)
        static let borderWidth: CGFloat = 1.0
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: Constants.viewStackSpacing) {
                
                // Email Activation View Hidden link
                NavigationLink(destination: SubscriptionEmailView(isAddingDevice: viewModel.isAddingDevice), isActive: $isActive) {
                    EmptyView()
                }.isDetailLink(false)
                
                headerView
                optionsView
                footerView
                
                Spacer()
            }.background(Color(designSystemColor: .background))
            
            
            .navigationTitle(viewModel.isAddingDevice ? UserText.subscriptionAddDeviceTitle : UserText.subscriptionActivate)
            .navigationBarBackButtonHidden(viewModel.transactionStatus != .idle)
            .applyInsetGroupedListStyle()
            
            .alert(isPresented: $isAlertVisible) { getAlert() }
            
            .onChange(of: viewModel.activationResult) { result in
                if result != .unknown {
                    isAlertVisible = true
                }
            }
            .onAppear {
                viewModel.initializeView()
                setUpAppearances()
            }
            
            if viewModel.transactionStatus != .idle {
                PurchaseInProgressView(status: getTransactionStatus())
            }
        }
        
    }
    
    private var listItems: [ListItem] {
        [
            .init(id: 0,
                  content: getCellTitle(icon: Constants.emailIcon,
                                        text: UserText.subscriptionActivateEmail),
                  expandedContent: getEmailCellContent(buttonAction: { isActive = true }))
        ]
    }
    
    private func getCellTitle(icon: String, text: String) -> AnyView {
        AnyView(
            HStack {
                Image(icon)
                Text(text)
                    .daxSubheadSemibold()
                    .foregroundColor(Color(designSystemColor: .textPrimary))
            }
        )
    }
    
    private func getEmailCellContent(buttonAction: @escaping () -> Void) -> AnyView {
        AnyView(
            VStack(alignment: .leading) {
                if !viewModel.isAddingDevice {
                    Text(UserText.subscriptionActivateEmailDescription)
                        .daxSubheadRegular()
                        .foregroundColor(Color(designSystemColor: .textSecondary))
                    getCellButton(buttonText: UserText.subscriptionActivateEmailButton,
                                  action: {
                        DailyPixel.fireDailyAndCount(pixel: .privacyProRestorePurchaseEmailStart)
                        DailyPixel.fire(pixel: .privacyProWelcomeAddDevice)
                        buttonAction()
                    })
                } else if viewModel.subscriptionEmail == nil {
                    Text(UserText.subscriptionAddDeviceEmailDescription)
                        .daxSubheadRegular()
                        .foregroundColor(Color(designSystemColor: .textSecondary))
                    getCellButton(buttonText: UserText.subscriptionRestoreAddEmailButton,
                                  action: {
                        Pixel.fire(pixel: .privacyProAddDeviceEnterEmail)
                        buttonAction()
                    })
                } else {
                    Text(viewModel.subscriptionEmail ?? "").daxSubheadSemibold()
                    Text(UserText.subscriptionManageEmailDescription)
                        .daxSubheadRegular()
                        .foregroundColor(Color(designSystemColor: .textSecondary))
                    HStack {
                        getCellButton(buttonText: UserText.subscriptionManageEmailButton,
                                      action: {
                            Pixel.fire(pixel: .privacyProSubscriptionManagementEmail)
                            buttonAction()
                        })
                    }
                }
            })
    }
    
    private func getCellButton(buttonText: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action, label: {
                Text(buttonText)
                    .daxButton()
                    .padding(Constants.buttonInsets)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                            .stroke(Color.clear, lineWidth: 1)
                    )
            })
            .background(Color(designSystemColor: .accent))
            .cornerRadius(Constants.buttonCornerRadius)
            .padding(.top, Constants.cellLineSpacing)
        )
    }
                
    private func getTransactionStatus() -> String {
        switch viewModel.transactionStatus {
        case .polling:
            return UserText.subscriptionCompletingPurchaseTitle
        case .purchasing:
            return UserText.subscriptionPurchasingTitle
        case .restoring:
            return UserText.subscriptionRestoringTitle
        case .idle:
            return ""
        }
    }
    
    private var headerView: some View {
        VStack(spacing: Constants.headerLineSpacing) {
            Image(Constants.heroImage).padding(.bottom, Constants.cellLineSpacing)
            Text(viewModel.isAddingDevice ? UserText.subscriptionAddDeviceHeaderTitle : UserText.subscriptionActivateTitle)
                .daxHeadline()
                .multilineTextAlignment(.center)
                .foregroundColor(Color(designSystemColor: .textPrimary))
            Text(viewModel.isAddingDevice ? UserText.subscriptionAddDeviceDescription : UserText.subscriptionActivateHeaderDescription)
                .daxFootnoteRegular()
                .foregroundColor(Color(designSystemColor: .textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(Constants.headerPadding)
    }
    
    @ViewBuilder
    private var footerView: some View {
        if !viewModel.isAddingDevice {
            VStack(alignment: .leading, spacing: Constants.footerLineSpacing) {
                Text(UserText.subscriptionActivateDescription)
                    .daxFootnoteRegular()
                    .foregroundColor(Color(designSystemColor: .textSecondary))
                Button(action: {
                    viewModel.restoreAppstoreTransaction()
                }, label: {
                    Text(UserText.subscriptionRestoreAppleID)
                        .daxFootnoteSemibold()
                        .foregroundColor(Color(designSystemColor: .accent))
                })
            }
            .padding(Constants.listPadding)
        }
    }
    
    private var optionsView: some View {
        VStack {
            ForEach(Array(zip(listItems.indices, listItems)), id: \.1.id) { _, item in
                VStack(alignment: .leading, spacing: Constants.cellLineSpacing) {
                    HStack {
                        item.content
                        Spacer()
                        if listItems.count > 1 {
                            Image(systemName: expandedItemId == item.id ? Constants.openIndicator : Constants.closedIndicator)
                                .foregroundColor(Color(designSystemColor: .textPrimary))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        expandedItemId = expandedItemId == item.id ? 0 : item.id
                    }
                    if expandedItemId == item.id {
                        item.expandedContent
                    }
                }
                .padding(Constants.cellPadding)
                .background(Color(designSystemColor: .panel))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(Color(designSystemColor: .lines), lineWidth: Constants.borderWidth)
                )
                .padding(Constants.listPadding)
            }
        }
    }
        
    private func getAlert() -> Alert {
        switch viewModel.activationResult {
        case .activated:
            return Alert(title: Text(UserText.subscriptionRestoreSuccessfulTitle),
                         message: Text(UserText.subscriptionRestoreSuccessfulMessage),
                         dismissButton: .default(Text(UserText.subscriptionRestoreSuccessfulButton)) {
                            dismiss()
                         }
            )
        case .notFound:
            return Alert(title: Text(UserText.subscriptionRestoreNotFoundTitle),
                         message: Text(UserText.subscriptionRestoreNotFoundMessage),
                         primaryButton: .default(Text(UserText.subscriptionRestoreNotFoundPlans),
                                                 action: {
                                                    dismiss()
                                                 }),
                         secondaryButton: .cancel())
            
        case .expired:
            return Alert(title: Text(UserText.subscriptionRestoreNotFoundTitle),
                         message: Text(UserText.subscriptionRestoreNotFoundMessage),
                         primaryButton: .default(Text(UserText.subscriptionRestoreNotFoundPlans),
                                                 action: {
                                                    dismiss()
                                                 }),
                         secondaryButton: .cancel())
        default:
            return Alert(
                title: Text(UserText.subscriptionBackendErrorTitle),
                message: Text(UserText.subscriptionBackendErrorMessage),
                dismissButton: .cancel(Text(UserText.subscriptionBackendErrorButton)) {
                    onDismissStack?()
                    dismiss()
                }
            )
        }
    }
    
    private func setUpAppearances() {
        let navAppearance = UINavigationBar.appearance()
        navAppearance.backgroundColor = UIColor(designSystemColor: .background)
        navAppearance.barTintColor = UIColor(designSystemColor: .surface)
        navAppearance.shadowImage = UIImage()
        navAppearance.tintColor = UIColor(designSystemColor: .textPrimary)
    }
    
    struct ListItem {
        let id: Int
        let content: AnyView
        let expandedContent: AnyView
    }
    
}

@available(iOS 15.0, *)
struct SubscriptionRestoreView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionRestoreView()
            .previewDevice("iPhone 12")
    }
}

// Commented out because CI fails if a SwiftUI preview is enabled https://app.asana.com/0/414709148257752/1206774081310425/f
// @available(iOS 15.0, *)
// struct SubscriptionRestoreView_Previews: PreviewProvider {
//    static var previews: some View {
//        SubscriptionRestoreView()
//    }
// }

#endif

import Foundation

/// Configuration service that saves app settings to a JSON file
/// instead of using UserDefaults for better portability
class ConfigService: ObservableObject {
    static let shared = ConfigService()
    
    @Published var config: AppConfig {
        didSet {
            save()
        }
    }
    
    private var configURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appFolder = appSupport.appendingPathComponent("LireFlow", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        return appFolder.appendingPathComponent("config.json")
    }
    
    private init() {
        self.config = AppConfig()
        load()
    }
    
    func load() {
        guard let configURL = configURL,
              FileManager.default.fileExists(atPath: configURL.path) else { return }

        do {
            let data = try Data(contentsOf: configURL)
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
        }
    }
    
    func save() {
        guard let configURL = configURL else { return }
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL, options: .atomic)

            // Set file permissions to 0600 (read/write for owner only) for security
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: configURL.path
            )
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    /// Get the config file path (for user reference)
    var configFilePath: String {
        configURL?.path ?? "Unable to determine config path"
    }
}

// MARK: - Article Layout

enum ArticleLayout: String, Codable, CaseIterable {
    case standard = "standard"
    case card = "card"
    case compact = "compact"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .card: return "Card"
        case .compact: return "Compact"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "list.bullet"
        case .card: return "rectangle.grid.1x2"
        case .compact: return "list.dash"
        }
    }
}

/// Europresse portal configuration
struct EuropressePortal: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let authURL: String
    
    static let availablePortals: [EuropressePortal] = [
        // FRANCE - Bibliothèques Nationales
        EuropressePortal(name: "BnF - Bibliothèque nationale de France", authURL: "https://bnf.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=D000067U_1"),
        EuropressePortal(name: "BPI - Bibliothèque Publique d'Information (Centre Pompidou)", authURL: "https://bpi.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=pompi"),
        EuropressePortal(name: "BnU - Bibliothèque nationale et universitaire de Strasbourg", authURL: "https://acces-distant.bnu.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=bnus"),
        EuropressePortal(name: "Bibliothèque Sainte-Geneviève (BSG)", authURL: "http://bsg-ezproxy.univ-paris3.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=pantheonT_1"),
        
        // FRANCE - Grandes Écoles
        EuropressePortal(name: "AgroParisTech", authURL: "https://ezproxy.universite-paris-saclay.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031535T_11"),
        EuropressePortal(name: "École Centrale de Lyon (ECL)", authURL: "https://ec-lyon.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=LYONT_7"),
        EuropressePortal(name: "École Centrale de Nantes", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=CENTRALENANTEST_1"),
        EuropressePortal(name: "École des Ponts ParisTech", authURL: "https://extranet.enpc.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=umiv"),
        EuropressePortal(name: "École normale supérieure de Lyon (ENS Lyon)", authURL: "https://acces.bibliotheque-diderot.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ENSLYONT_1"),
        EuropressePortal(name: "École normale supérieure de Paris (ENS Ulm)", authURL: "https://proxy.rubens.ens.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=PSLT_1"),
        EuropressePortal(name: "École polytechnique", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=U033137T_1"),
        EuropressePortal(name: "ENSAE Paris / ENSAI", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=U033137T_1"),
        EuropressePortal(name: "ENSAM - Arts et Métiers", authURL: "https://rp1.ensam.eu/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=AML"),
        EuropressePortal(name: "ENSTA Bretagne", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=ENSTAT_1"),
        EuropressePortal(name: "ENSTA Paris", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=U033137T_9"),
        EuropressePortal(name: "ENSSIB - École nationale supérieure des sciences de l'information et des bibliothèques", authURL: "http://nouveau.europresse.com.docelec.enssib.fr/access/ip/default.aspx?un=ENSSIBT_1"),
        EuropressePortal(name: "INSA Lyon", authURL: "https://docelec.insa-lyon.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=INSAT_3"),
        EuropressePortal(name: "INSA Rennes", authURL: "http://rproxy.insa-rennes.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=INSAT_1"),
        EuropressePortal(name: "Télécom Paris", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=U033137T_1"),
        EuropressePortal(name: "Télécom SudParis & IMT Business School", authURL: "http://mediaproxy.imtbs-tsp.eu/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U033137T_8"),
        
        // FRANCE - Business Schools
        EuropressePortal(name: "EM Lyon Business School", authURL: "https://em-lyon.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=EMLYONT_1"),
        EuropressePortal(name: "ESC Clermont Business School", authURL: "https://esc-clermont.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ESCT_1"),
        EuropressePortal(name: "ESCP Business School", authURL: "https://login.revproxy.escpeurope.eu/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=escpT_1"),
        EuropressePortal(name: "ESSEC Business School", authURL: "https://essec.idm.oclc.org/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=ESSECT_1"),
        EuropressePortal(name: "HEC Paris", authURL: "http://login.ezproxy.hec.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=josasT_1"),
        EuropressePortal(name: "Rennes School of Business", authURL: "https://rennes-sb.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=RENNES2T_2"),
        EuropressePortal(name: "TBS Education (Toulouse Business School)", authURL: "http://hub.tbs-education.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=CAPITOLET_11ip"),
        
        // FRANCE - Sciences Po
        EuropressePortal(name: "Sciences Po Bordeaux", authURL: "http://proxy.sciencespobordeaux.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=SCIENCESPOT_1"),
        EuropressePortal(name: "Sciences Po Grenoble", authURL: "http://iepnomade.grenet.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=IEPT_1"),
        EuropressePortal(name: "Sciences Po Lyon", authURL: "http://ressources.sciencespo-lyon.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=LYONT_5"),
        EuropressePortal(name: "Sciences Po Paris", authURL: "https://scpo.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=SCIENCESPO_1"),
        
        // FRANCE - Universités Paris et Île-de-France
        EuropressePortal(name: "CY Cergy Paris Université", authURL: "https://bibdocs.u-cergy.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031547T_1"),
        EuropressePortal(name: "Humathèque Campus Condorcet", authURL: "https://ezproxy.campus-condorcet.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=EPCS"),
        EuropressePortal(name: "Université Gustave Eiffel", authURL: "https://univ-eiffel.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=D000030T_5"),
        EuropressePortal(name: "Université Paris 1 Panthéon-Sorbonne", authURL: "https://ezpaarse.univ-paris1.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=SORBONNET_1"),
        EuropressePortal(name: "Université Paris 2 Panthéon-Assas", authURL: "https://docelec-u-paris2.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ASSAST_1"),
        EuropressePortal(name: "Université Paris 8 Vincennes-Saint-Denis", authURL: "https://accesdistant.bu.univ-paris8.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=paris8"),
        EuropressePortal(name: "Université Paris Cité", authURL: "https://ezproxy.u-paris.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UNIVPARIS"),
        EuropressePortal(name: "Université Paris Nanterre", authURL: "http://faraway.parisnanterre.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=Paris10T_1"),
        EuropressePortal(name: "Université Paris-Est Créteil (UPEC)", authURL: "https://ezproxy.u-pec.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=D000030T_4"),
        EuropressePortal(name: "Université Paris-Saclay", authURL: "https://ezproxy.universite-paris-saclay.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=U031535T_9"),
        EuropressePortal(name: "Université PSL (Paris Sciences & Lettres)", authURL: "https://portail.psl.eu/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=PSLT_1"),
        EuropressePortal(name: "Université Sorbonne Nouvelle - Paris 3", authURL: "http://ezproxy.univ-paris3.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=pantheonT_1"),
        EuropressePortal(name: "Université Sorbonne Paris Nord - Paris 13", authURL: "https://login.ezproxy.univ-paris13.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=paris13"),
        EuropressePortal(name: "Sorbonne Université", authURL: "https://accesdistant.sorbonne-universite.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UPMCT_1"),
        
        // FRANCE - Universités Province
        EuropressePortal(name: "Aix-Marseille Université", authURL: "https://lama.univ-amu.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031032T_1"),
        EuropressePortal(name: "La Rochelle Université", authURL: "https://gutenberg.univ-lr.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ROCHELLET_1"),
        EuropressePortal(name: "Le Mans Université", authURL: "https://login.doc-elec.univ-lemans.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031524T_1"),
        EuropressePortal(name: "Nantes Université", authURL: "https://bunantes.idm.oclc.org/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=NANTEST_1"),
        EuropressePortal(name: "Université Bordeaux Montaigne", authURL: "https://ezproxy.u-bordeaux-montaigne.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UNIVMONTAIGNET_1"),
        EuropressePortal(name: "Université Catholique de Lille", authURL: "https://login.ezproxy.univ-catholille.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=Vauban2T_1"),
        EuropressePortal(name: "Université Catholique de l'Ouest", authURL: "https://srvext.uco.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UCOT_1"),
        EuropressePortal(name: "Université Clermont Auvergne", authURL: "https://ezproxy.uca.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=FERRANDU_1"),
        EuropressePortal(name: "Université Claude Bernard Lyon 1", authURL: "http://docelec.univ-lyon1.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U033081T_1"),
        EuropressePortal(name: "Université Côte d'Azur (Nice)", authURL: "http://proxy.unice.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U032557T_1"),
        EuropressePortal(name: "Université d'Angers", authURL: "https://buadistant.univ-angers.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BUANGERST_1"),
        EuropressePortal(name: "Université d'Artois", authURL: "http://ezproxy.univ-artois.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=littoralT_1"),
        EuropressePortal(name: "Université d'Avignon", authURL: "https://buproxy2.univ-avignon.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=AvignonT_1"),
        EuropressePortal(name: "Université de Bordeaux", authURL: "https://docelec.u-bordeaux.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UNIVBORDEAUXT_1"),
        EuropressePortal(name: "Université de Bourgogne", authURL: "http://proxy-scd.u-bourgogne.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U032591T_1"),
        EuropressePortal(name: "Université de Bretagne Occidentale (Brest)", authURL: "http://scd-proxy.univ-brest.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=OCCIDENTALET_1"),
        EuropressePortal(name: "Université Bretagne Sud", authURL: "http://ezproxy.univ-ubs.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=BRETAGNESUDT_1"),
        EuropressePortal(name: "Université de Caen Normandie", authURL: "http://ezproxy.normandie-univ.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031221T_3"),
        EuropressePortal(name: "Université de Franche-Comté", authURL: "http://scd1.univ-fcomte.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=FCOMTET_1"),
        EuropressePortal(name: "Université de Haute-Alsace", authURL: "https://scd-proxy.uha.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=ALSACET_1"),
        EuropressePortal(name: "Université de La Réunion", authURL: "https://elgebar.univ-reunion.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BUREUNIONT_1"),
        EuropressePortal(name: "Université de Limoges", authURL: "https://ezproxy.unilim.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031697T_1"),
        EuropressePortal(name: "Université de Lille", authURL: "https://ressources-electroniques.univ-lille.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=TourcoingT_1"),
        EuropressePortal(name: "Université de Lorraine", authURL: "https://login.bases-doc.univ-lorraine.fr/login?qurl=http://nouveau.europresse.com/access/ip/default.aspx?un=NANCY2"),
        EuropressePortal(name: "Université de Montpellier", authURL: "https://login.ezpum.scdi-montpellier.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=MontpellierT_1"),
        EuropressePortal(name: "Université de Nîmes", authURL: "https://federation.unimes.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=NimesT_1"),
        EuropressePortal(name: "Université de Pau et des Pays de l'Adour", authURL: "https://rproxy.univ-pau.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=uppaT_2"),
        EuropressePortal(name: "Université de Perpignan Via Domitia", authURL: "https://ezproxy.univ-perp.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=U031536T_1"),
        EuropressePortal(name: "Université de Picardie Jules Verne (Amiens)", authURL: "https://merlin.u-picardie.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BUPICARDIET_2"),
        EuropressePortal(name: "Université de Poitiers", authURL: "http://ressources.univ-poitiers.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U032521T_1"),
        EuropressePortal(name: "Université de Reims Champagne-Ardenne", authURL: "https://urca.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ArdenneT_1"),
        EuropressePortal(name: "Université de Rennes", authURL: "https://passerelle.univ-rennes1.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=RENNES1AT_1"),
        EuropressePortal(name: "Université Rennes 2", authURL: "https://distant.bu.univ-rennes2.fr/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=RENNES22T_1"),
        EuropressePortal(name: "Université de Rouen Normandie", authURL: "http://ezproxy.normandie-univ.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031221T_4"),
        EuropressePortal(name: "Université de Strasbourg", authURL: "https://acces-distant.bnu.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=bnus"),
        EuropressePortal(name: "Université de Toulon", authURL: "http://ezproxy.univ-tln.fr:2048/login?url=http://nouveau.europresse.com/access/ip/default.aspx?un=ToulonT_1"),
        EuropressePortal(name: "Université de Tours", authURL: "https://proxy.scd.univ-tours.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=butours"),
        EuropressePortal(name: "Université des Antilles", authURL: "http://bu-services.univ-antilles.fr:5000/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=ANTILLEST_1"),
        EuropressePortal(name: "Université d'Orléans", authURL: "https://ezproxy.univ-orleans.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=OrleansT_1"),
        EuropressePortal(name: "Université du Littoral Côte d'Opale (ULCO)", authURL: "https://ezproxy.univ-littoral.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=dunkerqueT_1"),
        EuropressePortal(name: "Université Grenoble Alpes", authURL: "https://sid2nomade-2.grenet.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=grenobleT_1"),
        EuropressePortal(name: "Université Jean Monnet Saint-Étienne", authURL: "https://ujm.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=MONNETT_1"),
        EuropressePortal(name: "Université Jean Moulin Lyon 3", authURL: "http://ezscd.univ-lyon3.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=MOULINT_1"),
        EuropressePortal(name: "Université Le Havre Normandie", authURL: "http://ezproxy.normandie-univ.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031221T_6"),
        EuropressePortal(name: "Université Lumière Lyon 2", authURL: "http://bibelec.univ-lyon2.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=LYONT_3"),
        EuropressePortal(name: "Université Paris-Saclay (étudiants)", authURL: "https://eztest.biblio.univ-evry.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031535T_9"),
        EuropressePortal(name: "Université Paul-Valéry Montpellier 3", authURL: "https://login.ezpupv.scdi-montpellier.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=MontpellierT_1"),
        EuropressePortal(name: "Université Polytechnique Hauts-de-France (Valenciennes)", authURL: "http://ezproxy.uphf.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=valenciennesT_1"),
        EuropressePortal(name: "Université Savoie Mont Blanc", authURL: "https://univ-smb.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=savoieT_1"),
        EuropressePortal(name: "Université Toulouse 1 Capitole", authURL: "https://gorgone.univ-toulouse.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=CAPITOLET_1"),
        EuropressePortal(name: "Université Toulouse Jean Jaurès", authURL: "https://gorgone.univ-toulouse.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=CAPITOLET_5"),
        EuropressePortal(name: "Université Toulouse III Paul Sabatier", authURL: "https://gorgone.univ-toulouse.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=CAPITOLET_6"),
        EuropressePortal(name: "UTC - Université de Technologie de Compiègne", authURL: "https://ezproxy.utc.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BUCOMPIEGNET_2"),
        EuropressePortal(name: "UTBM - Université de Technologie de Belfort-Montbéliard", authURL: "https://ezproxy.utbm.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=UTBMT_2"),
        EuropressePortal(name: "UTT - Université de Technologie de Troyes", authURL: "http://proxy.utt.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BUTROYEST_2"),
        
        // FRANCE - Autres institutions
        EuropressePortal(name: "CNAM - Conservatoire national des arts et métiers", authURL: "https://proxybib-pp.cnam.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=CNAM"),
        EuropressePortal(name: "EHESP - École des Hautes Études en Santé Publique", authURL: "https://login.ehesp.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U032196T_1"),
        EuropressePortal(name: "ENTPE - École nationale des travaux publics de l'État", authURL: "https://nouveau-europresse-com.eu1.proxy.openathens.net/access/ip/default.aspx?un=ENTPET_1"),
        EuropressePortal(name: "VetAgro Sup", authURL: "https://ezproxy.vetagro-sup.fr/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U032869T_1"),
        EuropressePortal(name: "University of Cambridge", authURL: "https://ezp.lib.cam.ac.uk/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U031883T_1"),
        
        // BELGIQUE
        EuropressePortal(name: "UCLouvain (Belgique)", authURL: "https://nouveau-europresse-com.proxy.bib.uclouvain.be:2443"),
        EuropressePortal(name: "ULB - Université Libre de Bruxelles (Belgique)", authURL: "http://nouveau.europresse.com.ezproxy.ulb.ac.be/access/ip/default.aspx?un=LIBRET_1"),
        EuropressePortal(name: "Université de Liège (Belgique)", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=U031558T_1"),
        
        // SUISSE
        EuropressePortal(name: "Eduvaud - Canton de Vaud (Suisse)", authURL: "https://nouveau.europresse.com/access/ip/default.aspx?un=lausanneAT_1"),
        
        // LUXEMBOURG
        EuropressePortal(name: "BnL - Bibliothèque nationale du Luxembourg", authURL: "http://proxy.bnl.lu/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=U030612T_1"),
        
        // CANADA
        EuropressePortal(name: "BAnQ - Bibliothèque et Archives nationales du Québec", authURL: "http://res.banq.qc.ca/login?url=https://nouveau.eureka.cc/access/ip/default.aspx?un=bnat1"),
        EuropressePortal(name: "Bibliothèque publique d'Ottawa (Canada)", authURL: "https://ezproxy.biblioottawalibrary.ca/login?qurl=https://nouveau.eureka.cc/access/ip/default.aspx?un=opladminU_1"),
        
        // FRANCE - Médiathèques
        EuropressePortal(name: "Bibliothèque municipale de Lyon", authURL: "https://connect.bm-lyon.fr/get/login?&access_list=LVAw&url=aHR0cHM6Ly9ub3V2ZWF1LmV1cm9wcmVzc2UuY29tL2FjY2Vzcy9odHRwcmVmL2RlZmF1bHQuYXNweD91bj1CTUxZT05BVV8x"),
        EuropressePortal(name: "Bibliothèques du Val d'Oise - RéVOdoc", authURL: "https://nouveau.europresse.com/access/httpref/default.aspx?un=VALDOISEU_2"),
        EuropressePortal(name: "E-médias Savoie Mont Blanc", authURL: "https://e-medias.biblio7374.fr/Portal/ASSARedirect.ashx?url=https://nouveau.europresse.com/access/httpref/default.aspx?un=PringyU_2"),
        EuropressePortal(name: "Médiathèques d'Antony", authURL: "https://nouveau.europresse.com/access/httpref/default.aspx?un=antonyU_2"),
        EuropressePortal(name: "Numothèque - Métropole de Grenoble", authURL: "https://numotheque.grenoblealpesmetropole.fr/Default/redirection-contenu-europresse.aspx"),
        EuropressePortal(name: "Toulouse Métropole - MaBM", authURL: "https://mabm.toulouse-metropole.fr/Portal/ASSARedirect.ashx?url=https://nouveau.europresse.com/access/httpref/default.aspx?un=bmtoulouseAU_1"),
    ]
}

/// App configuration stored in JSON file
struct AppConfig: Codable {
    var isDarkMode: Bool = false
    var refreshIntervalMinutes: Int = 30
    var showUnreadCount: Bool = true
    var defaultFeedCategory: String = "Tech"
    var articleFontSize: Int = 16
    var markAsReadOnScroll: Bool = true

    // Weather settings
    var showWeather: Bool = true
    var weatherLocation: String? = nil  // nil = auto-detect

    // UI preferences
    var sidebarWidth: Double = 240
    var articleListWidth: Double = 320
    var articleLayout: ArticleLayout = .standard

    // Performance settings
    var loadImages: Bool = true
    var maxArticlesPerFeed: Int = 500
    var cleanupOldArticlesDays: Int = 30
    var backgroundRefreshEnabled: Bool = true
    
    // Europresse integration
    var europressePortal: EuropressePortal? = nil
    
    // Onboarding
    var hasCompletedOnboarding: Bool = false
    
    // Theme
    var selectedTheme: AppTheme = .system
}


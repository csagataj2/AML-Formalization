From Coq Require Import ssreflect ssrfun ssrbool.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

From Coq.Logic Require Import FunctionalExtensionality PropExtensionality Classical_Pred_Type Classical_Prop.
From Coq.micromega Require Import Lia.
From Coq.Program Require Import Wf.

From stdpp Require Import base fin_sets.
From stdpp Require Import pmap gmap mapset fin_sets sets propset.

From MatchingLogic.Utils Require Import Lattice stdpp_ext extralibrary.
From MatchingLogic Require Import Syntax NamedAxioms IndexManipulation.

Import MatchingLogic.Syntax.Notations.
(** ** Matching Logic Semantics *)
Section semantics.
  
  Context {signature : Signature}.

  Definition Power (Sigma : Type) := propset Sigma.

  (* Model of AML ref. snapshot: Definition 2 *)

  Record Model := {
    Domain : Type;
    Domain_inhabited : Inhabited Domain;
    app_interp : Domain -> Domain -> Power Domain;
    sym_interp (sigma : symbols) : Power Domain;
  }.

  Definition Empty {M : Model} : Power (Domain M) := @empty (Power (Domain M)) _.
  Definition Full {M : Model} : Power (Domain M) := @top (Power (Domain M)) _.

  (* full set and empty set are distinct *)
  Lemma empty_impl_not_full : forall {M : Model} (S : Power (Domain M)),
      S = Empty -> S <> Full.
  Proof.
    intros M S H.
    intros HContra. rewrite -> HContra in H.
    assert (Hw1: (@inhabitant _ (Domain_inhabited M)) ∈ (@Full M)).
    { unfold Full. apply elem_of_top. exact I. }
    rewrite H in Hw1.
    unfold Empty in Hw1.
    apply not_elem_of_empty in Hw1. exact Hw1.
  Qed.

  Lemma full_impl_not_empty : forall {M : Model} (S : Power (Domain M)),
      S = Full -> S <> Empty.
  Proof.
    intros M S H HContra.
    rewrite -> HContra in H.
    assert (Hw1: (@inhabitant _ (Domain_inhabited M)) ∈ Full).
    { unfold Full. apply elem_of_top. exact I. }
    rewrite <- H in Hw1.
    unfold Empty in Hw1.
    apply not_elem_of_empty in Hw1. exact Hw1.
  Qed.

  (* element and set variable valuations *)
  Definition EVarVal {m : Model} : Type := evar -> Domain m.
  Definition SVarVal {m : Model} : Type := svar -> Power (Domain m).

  Definition update_evar_val {m : Model} 
             (v : evar) (x : Domain m) (evar_val : @EVarVal m) : EVarVal :=
    fun v' : evar => if decide (v = v') is left _ then x else evar_val v'.

  Definition update_svar_val {m : Model}
             (v : svar) (X : Power (Domain m)) (svar_val : @SVarVal m)  : SVarVal :=
    fun v' : svar => if decide (v = v') is left _ then X else svar_val v'.

  Lemma update_svar_val_comm M :
    forall (X1 X2 : svar) (S1 S2 : Power (Domain M)) (svar_val : @SVarVal M),
      X1 <> X2 ->
      update_svar_val X1 S1 (update_svar_val X2 S2 svar_val)
      = update_svar_val X2 S2 (update_svar_val X1 S1 svar_val).
  Proof.
    intros.
    unfold update_svar_val.
    apply functional_extensionality.
    intros.
    destruct (decide (X1 = x)),(decide (X2 = x)); subst.
    * unfold not in H. assert (x = x). reflexivity. apply H in H0. destruct H0.
    * reflexivity.
    * reflexivity.
    * reflexivity.
  Qed.

  Lemma update_svar_val_shadow M : forall (X : svar)
                                          (S1 S2 : Power (Domain M))
                                          (svar_val : @SVarVal M),
      update_svar_val X S1 (update_svar_val X S2 svar_val) = update_svar_val X S1 svar_val.
  Proof.
    intros. unfold update_svar_val. apply functional_extensionality.
    intros. destruct (decide (X = x)); reflexivity.
  Qed.

  Lemma update_svar_val_neq M (ρₛ : @SVarVal M) X1 S X2 :
    X1 <> X2 -> update_svar_val X1 S ρₛ X2 = ρₛ X2.
  Proof.
    unfold update_svar_val. intros.
    destruct (decide (X1 = X2)); simpl.
    - contradiction.
    - auto.
  Qed.
  
  Lemma update_evar_val_comm M :
    forall (x1 x2 : evar) (m1 m2 : Domain M) (evar_val : @EVarVal M),
      x1 <> x2 ->
      update_evar_val x1 m1 (update_evar_val x2 m2 evar_val)
      = update_evar_val x2 m2 (update_evar_val x1 m1 evar_val).
  Proof.
    intros.
    unfold update_evar_val.
    apply functional_extensionality.
    intros.
    destruct (decide (x1 = x)),(decide (x2 = x)); subst.
    * unfold not in H. assert (x = x). reflexivity. apply H in H0. destruct H0.
    * reflexivity.
    * reflexivity.
    * reflexivity.
  Qed.

  Lemma update_evar_val_shadow M : forall (x : evar)
                                          (m1 m2 : Domain M)
                                          (evar_val : @EVarVal M),
      update_evar_val x m1 (update_evar_val x m2 evar_val) = update_evar_val x m1 evar_val.
  Proof.
    intros. unfold update_evar_val. apply functional_extensionality.
    intros. destruct (decide (x = x0)); reflexivity.
  Qed.

  Lemma update_evar_val_same M x m ρₑ : @update_evar_val M x m ρₑ x = m.
  Proof.
    unfold update_evar_val. destruct (decide (x = x)); simpl.
    + reflexivity.
    + contradiction.
  Qed.

  Lemma update_evar_val_neq M (ρₑ : @EVarVal M) x1 e x2 :
    x1 <> x2 -> update_evar_val x1 e ρₑ x2 = ρₑ x2.
  Proof.
    unfold update_evar_val. intros.
    destruct (decide (x1 = x2)); simpl.
    - contradiction.
    - auto.
  Qed.

  Lemma update_evar_val_same_2 M x ρₑ : @update_evar_val M x (ρₑ x) ρₑ = ρₑ.
  Proof.
    apply functional_extensionality. intros x0.
    unfold update_evar_val. destruct (decide (x = x0)); simpl.
    - subst. reflexivity.
    - reflexivity.
  Qed.

  Lemma update_svar_val_same M x m ρₑ : @update_svar_val M x m ρₑ x = m.
  Proof.
    unfold update_svar_val. destruct (decide (x = x)); simpl.
    + reflexivity.
    + contradiction.
  Qed.

  Lemma update_svar_val_same_2 M x ρₑ : @update_svar_val M x (ρₑ x) ρₑ = ρₑ.
  Proof.
    apply functional_extensionality. intros x0.
    unfold update_svar_val. destruct (decide (x = x0)); simpl.
    - subst. reflexivity.
    - reflexivity.
  Qed.


  (* We use propositional extensionality here. *)
  Global Instance propset_leibniz_equiv {m : Model} : LeibnizEquiv (Power (Domain m)).
  Proof.
    intros x y H. unfold equiv in H. unfold set_equiv_instance in H.
    unfold Power in x,y. destruct x,y.
    apply f_equal. apply functional_extensionality.
    intros x. apply propositional_extensionality.
    specialize (H x). destruct H as [H1 H2].
    split; auto.
  Qed.
  
  (* extending pointwise application *)
  Definition app_ext {m : Model}
             (l r : Power (Domain m)) :
    Power (Domain m) :=
    PropSet (fun (e : (Domain m)) => exists (le re : (Domain m)), le ∈ l /\ re ∈ r /\ e ∈ (@app_interp m) le re).

  Lemma app_ext_bot_r : forall (m : Model),
      forall S : Power (Domain m),
        app_ext S ∅ = ∅.
  Proof.
    intros m S. unfold app_ext.
    rewrite -> elem_of_equiv_empty_L.
    intros x Hcontra. rewrite -> elem_of_PropSet in Hcontra.
    destruct Hcontra as [le [re [H1 [H2 H3] ] ] ].
    apply not_elem_of_empty in H2. exact H2.
  Qed.

  Lemma app_ext_bot_l : forall (m : Model),
      forall S : Power (Domain m),
        app_ext ∅ S = ∅.
  Proof.
    intros m S. unfold app_ext.
    rewrite -> elem_of_equiv_empty_L.
    intros x Hcontra. rewrite -> elem_of_PropSet in Hcontra.
    destruct Hcontra as [le [re [H1 [H2 H3] ] ] ].
    apply not_elem_of_empty in H1. exact H1.
  Qed.

  Lemma app_ext_monotonic_l : forall (m : Model),
      forall (S1 S2 S : Power (Domain m)),
        S1 ⊆ S2 -> (app_ext S1 S) ⊆ (app_ext S2 S).
  Proof.
    intros m S1 S2 S H. rewrite -> elem_of_subseteq in H.
    rewrite -> elem_of_subseteq. intros x H'.
    unfold app_ext in H'.
    rewrite -> elem_of_PropSet in H'.
    destruct H' as [le [re [H1 [H2 H3] ] ] ].
    unfold app_ext.
    rewrite -> elem_of_PropSet.
    exists le,re. firstorder.
  Qed.

  Lemma app_ext_monotonic_r : forall (m : Model),
      forall (S S1 S2 : Power (Domain m)),
        S1 ⊆ S2 -> (app_ext S S1) ⊆ (app_ext S S2).
  Proof.
    intros m S1 S2 S H. rewrite -> elem_of_subseteq in H.
    rewrite -> elem_of_subseteq. intros x H'.
    unfold app_ext in H'.
    rewrite -> elem_of_PropSet in H'.
    destruct H' as [le [re [H1 [H2 H3] ] ] ].
    unfold app_ext.
    rewrite -> elem_of_PropSet.
    exists le,re. firstorder.
  Qed.


  (* Semantics of AML ref. snapshot: Definition 3 *)

  Section with_model.
    Context {m : Model}.
    Let OS := PropsetOrderedSet (@Domain m).
    Let  L := PowersetLattice (@Domain m).

    Program Fixpoint pattern_interpretation
            (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
            (p : Pattern) {measure (size p)} :=
      match p with
      | patt_free_evar x => {[evar_val x]}
      | patt_free_svar X => svar_val X
      | patt_bound_evar x => ∅
      | patt_bound_svar X => ∅
      | patt_sym s => (@sym_interp m) s
      | patt_app ls rs => app_ext (pattern_interpretation evar_val svar_val ls)
                                  (pattern_interpretation evar_val svar_val rs)
      | patt_bott => ∅
      | patt_imp ls rs => (difference ⊤ (pattern_interpretation evar_val svar_val ls)) ∪
                                          (pattern_interpretation evar_val svar_val rs)
      | patt_exists p' =>
        let x := fresh_evar p' in
        propset_fa_union
          (fun e => pattern_interpretation (update_evar_val x e evar_val)
                                           svar_val
                                           (evar_open 0 x p'))
      | patt_mu p' =>
        let X := fresh_svar p' in
        @LeastFixpointOf _ OS L
                         (fun S => pattern_interpretation evar_val
                                                          (update_svar_val X S svar_val)
                                                          (svar_open 0 X p'))
      end.
    Next Obligation. intros. subst. simpl; lia. Defined.
    Next Obligation. intros. subst. simpl; lia. Defined.
    Next Obligation. intros. subst. simpl; lia. Defined.
    Next Obligation. intros. subst. simpl; lia. Defined.
    Next Obligation. intros. subst. simpl; rewrite <- evar_open_size. lia. Defined.
    Next Obligation. intros. subst. simpl; rewrite <- svar_open_size. lia. Defined.
    Next Obligation. Tactics.program_simpl. Defined.


    Definition Fassoc ρₑ ρₛ ϕ X :=
      λ S, pattern_interpretation ρₑ (update_svar_val X S ρₛ) ϕ.
    
    (* TODO: Need to be able to simplify Program Fixpoint definitions *)

    Lemma pattern_interpretation_free_evar_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (x : evar) :
      pattern_interpretation evar_val svar_val (patt_free_evar x) = {[ evar_val x ]}.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_free_svar_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (X : svar) :
      pattern_interpretation evar_val svar_val (patt_free_svar X) = svar_val X.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_bound_evar_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (x : db_index) :
      pattern_interpretation evar_val svar_val (patt_bound_evar x) = ∅.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_bound_svar_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (X : db_index) :
      pattern_interpretation evar_val svar_val (patt_bound_svar X) = ∅.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_sym_simpl
          (evar_val : @EVarVal m) (svar_val : @SVarVal m)
          (s : symbols) :
      pattern_interpretation evar_val svar_val (patt_sym s) = @sym_interp m s.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_app_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (ls rs : Pattern) :
      pattern_interpretation evar_val svar_val (patt_app ls rs) =
      app_ext (pattern_interpretation evar_val svar_val ls)
              (pattern_interpretation evar_val svar_val rs).
    Proof.
      unfold pattern_interpretation, pattern_interpretation_func.
      rewrite fix_sub_eq.
      intros x f g Heq.
      destruct x. Tactics.program_simpl. unfold projT1, projT2.
      destruct X; auto with f_equal.
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. }
    Qed.

    Lemma pattern_interpretation_bott_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m)) :
      pattern_interpretation evar_val svar_val patt_bott = ∅.
    Proof.
      auto.
    Qed.

    Lemma pattern_interpretation_imp_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (ls rs : Pattern) :
      pattern_interpretation evar_val svar_val (patt_imp ls rs) =
      (difference ⊤ (pattern_interpretation evar_val svar_val ls)) ∪
                      (pattern_interpretation evar_val svar_val rs).
    Proof.
      unfold pattern_interpretation, pattern_interpretation_func.
      rewrite fix_sub_eq.
      intros x f g Heq.
      destruct x. Tactics.program_simpl. unfold projT1, projT2.
      destruct X; auto with f_equal.
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. }
    Qed.

    Lemma pattern_interpretation_ex_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (p : Pattern) :
      pattern_interpretation evar_val svar_val (patt_exists p) =
      let x := fresh_evar p in
      propset_fa_union 
        (fun e => pattern_interpretation (update_evar_val x e evar_val)
                                         svar_val
                                         (evar_open 0 x p)).
    Proof.
      unfold pattern_interpretation, pattern_interpretation_func.
      rewrite fix_sub_eq.
      intros x f g Heq.
      destruct x. Tactics.program_simpl. unfold projT1, projT2.
      destruct X; auto with f_equal.
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. }
    Qed.

    Lemma pattern_interpretation_mu_simpl
          (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m))
          (p : Pattern) :
      pattern_interpretation evar_val svar_val (patt_mu p) =
      let X := fresh_svar p in
      @LeastFixpointOf _ OS L
                       (fun S => pattern_interpretation evar_val
                                                        (update_svar_val X S svar_val)
                                                        (svar_open 0 X p)).
    Proof.
      unfold pattern_interpretation, pattern_interpretation_func.
      rewrite fix_sub_eq.
      intros x f g Heq.
      destruct x. Tactics.program_simpl. unfold projT1, projT2.
      destruct X; auto with f_equal.
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. apply functional_extensionality; auto. }
      { f_equal. }
    Qed.

    (* TODO extend with derived constructs using typeclasses *)
    Definition pattern_interpretation_simpl :=
      ( pattern_interpretation_free_evar_simpl,
        pattern_interpretation_free_svar_simpl,
        pattern_interpretation_bound_evar_simpl,
        pattern_interpretation_bound_svar_simpl,
        pattern_interpretation_sym_simpl,  
        pattern_interpretation_app_simpl,
        pattern_interpretation_bott_simpl,
        pattern_interpretation_imp_simpl,
        pattern_interpretation_ex_simpl,
        pattern_interpretation_mu_simpl
      ).


  (**
   Proof of correct semantics for the derived operators
   ref. snapshot: Proposition 4
   *)

  End with_model.

  (* model predicate *)
  Definition M_predicate (M : Model) (ϕ : Pattern) : Prop := forall ρₑ ρ,
      @pattern_interpretation M ρₑ ρ ϕ = ⊤ \/ pattern_interpretation ρₑ ρ ϕ = ∅.

  Lemma M_predicate_impl M ϕ₁ ϕ₂ : M_predicate M ϕ₁ -> M_predicate M ϕ₂ -> M_predicate M (patt_imp ϕ₁ ϕ₂).
  Proof.
    unfold M_predicate. intros Hp1 Hp2 ρₑ ρ.
    specialize (Hp1 ρₑ ρ). specialize (Hp2 ρₑ ρ).
    rewrite -> pattern_interpretation_imp_simpl.
    destruct Hp1, Hp2; rewrite -> H; rewrite -> H0.
    + left. set_solver by fail.
    + right. set_solver by fail.
    + left. set_solver by fail.
    + left. set_solver by fail.
  Qed.

  Hint Resolve M_predicate_impl : core.

  Lemma M_predicate_bott M : M_predicate M patt_bott.
  Proof.
    unfold M_predicate. intros. right.
    apply pattern_interpretation_bott_simpl.
  Qed.

  Hint Resolve M_predicate_bott : core.

  Lemma M_predicate_exists M ϕ :
    let x := evar_fresh (elements (free_evars ϕ)) in
    M_predicate M (evar_open 0 x ϕ) -> M_predicate M (patt_exists ϕ).
  Proof.
    simpl. unfold M_predicate. intros.
    rewrite -> pattern_interpretation_ex_simpl.
    simpl.
    pose proof (H' := classic
                        (exists e : Domain M,
                            (pattern_interpretation
                               (update_evar_val (evar_fresh (elements (free_evars ϕ))) e ρₑ)
                               ρ
                               (evar_open 0 (evar_fresh (elements (free_evars ϕ))) ϕ))
                            = ⊤)).
    destruct H'.
    - (* For some member, the subformula evaluates to full set. *)
      left.
      apply set_eq_subseteq.
      split.
      { set_solver by fail. }
      apply elem_of_subseteq.
      intros x _.
      destruct H0 as [x0 H0]. unfold fresh_evar.
      unfold propset_fa_union. rewrite -> elem_of_PropSet.
      exists x0. rewrite H0. apply elem_of_top'.
    - (* The subformula does not evaluate to full set for any member. *)
      right.
      apply set_eq_subseteq.
      split.
      2: { apply empty_subseteq. }
      apply elem_of_subseteq.
      intros x H1.
      unfold propset_fa_union in H1.
      rewrite -> elem_of_PropSet in H1.
      destruct H1 as [c H1].
      unfold not in H0.
      specialize (H (update_evar_val (evar_fresh (elements (free_evars ϕ))) c ρₑ) ρ).
      destruct H.
      + exfalso. apply H0. exists c. apply H.
      + apply set_eq_subseteq in H. destruct H as [H _].
        rewrite ->  elem_of_subseteq in H. auto.
  Qed.

  Hint Resolve M_predicate_exists : core.

  Lemma predicate_not_empty_iff_full M ϕ ρₑ ρ :
    M_predicate M ϕ ->
    @pattern_interpretation M ρₑ ρ ϕ <> ∅ <->
    @pattern_interpretation M ρₑ ρ ϕ = ⊤.
  Proof.
    intros Hmp.
    split.
    - intros Hne. specialize (Hmp ρₑ ρ).
      destruct Hmp.
      + assumption.
      + contradiction.
    - intros Hf.
      apply full_impl_not_empty.
      assumption.
  Qed.

  Lemma predicate_not_full_iff_empty M ϕ ρₑ ρ :
    M_predicate M ϕ ->
    @pattern_interpretation M ρₑ ρ ϕ <> ⊤ <->
    @pattern_interpretation M ρₑ ρ ϕ = ∅.
  Proof.
    intros Hmp.
    split.
    - intros Hne. specialize (Hmp ρₑ ρ).
      destruct Hmp.
      + contradiction.
      + assumption.
    - intros Hf.
      apply empty_impl_not_full.
      assumption.
  Qed.

  Lemma pattern_interpretation_impl_MP M ϕ₁ ϕ₂ ρₑ ρ :
    @pattern_interpretation M ρₑ ρ (patt_imp ϕ₁ ϕ₂) = ⊤ ->
    @pattern_interpretation M ρₑ ρ ϕ₁ = ⊤ ->
    @pattern_interpretation M ρₑ ρ ϕ₂ = ⊤.
  Proof.
    unfold Full.
    rewrite pattern_interpretation_imp_simpl.
    intros H1 H2.
    rewrite -> H2 in H1.
    set_solver by auto.
  Qed.

  Lemma pattern_interpretation_predicate_impl M ϕ₁ ϕ₂ ρₑ ρ :
    M_predicate M ϕ₁ ->
    pattern_interpretation ρₑ ρ (patt_imp ϕ₁ ϕ₂) = ⊤
    <-> (pattern_interpretation ρₑ ρ ϕ₁ = ⊤
         -> @pattern_interpretation M ρₑ ρ ϕ₂ = ⊤).
  Proof.
    intros Hpred.
    split.
    - intros H H1.
      apply (pattern_interpretation_impl_MP H H1).
    - intros H.
      rewrite -> pattern_interpretation_imp_simpl.
      destruct (classic (pattern_interpretation ρₑ ρ ϕ₁ = ⊤)).
      + specialize (H H0).
        rewrite -> H. rewrite -> H0.
        set_solver by fail.
      + apply predicate_not_full_iff_empty in H0. 2: apply Hpred.
        rewrite -> H0.
        set_solver by fail.
  Qed.
  
  (* ϕ is a well-formed body of ex *)
  Lemma pattern_interpretation_exists_predicate_full M ϕ ρₑ ρ :
    let x := fresh_evar ϕ in
    M_predicate M (evar_open 0 x ϕ) ->
    pattern_interpretation ρₑ ρ (patt_exists ϕ) = ⊤ <->
    ∃ (m : Domain M), pattern_interpretation (update_evar_val x m ρₑ) ρ (evar_open 0 x ϕ) = ⊤.
  Proof.
    intros x Hpred.
    pose proof (Hpredex := M_predicate_exists Hpred).
    rewrite -[pattern_interpretation _ _ _ = ⊤]predicate_not_empty_iff_full. 2: auto.
    
    (*
        (* TODO: I would like to simplify the RHS, but cannot find a way. *)
        under [fun m => _]functional_extensionality => m.
        (* This fails *)
        Fail rewrite <- predicate_not_empty_iff_full.
        Fail rewrite -[_ = Full]predicate_not_empty_iff_full.
        over.
     *)


    rewrite -> Not_Empty_iff_Contains_Elements.
    split.
    - intros [x0 Hx0].
      rewrite -> pattern_interpretation_ex_simpl in Hx0.
      simpl in Hx0. unfold propset_fa_union in Hx0. rewrite -> elem_of_PropSet in Hx0.
      destruct Hx0 as [c Hc].
      exists c.
      rewrite -predicate_not_empty_iff_full. 2: assumption.
      rewrite Not_Empty_iff_Contains_Elements.
      exists x0. apply Hc.
    - intros [m Hm].
      apply full_impl_not_empty in Hm.
      apply Not_Empty_iff_Contains_Elements in Hm.
      destruct Hm as [x0 Hx0].
      exists x0.
      rewrite pattern_interpretation_ex_simpl. simpl.
      unfold propset_fa_union. rewrite -> elem_of_PropSet.
      exists m. assumption.
  Qed.

  Lemma pattern_interpretation_exists_empty M ϕ ρₑ ρ :
    let x := fresh_evar ϕ in
    pattern_interpretation ρₑ ρ (patt_exists ϕ) = ∅ <->
    ∀ (m : Domain M), pattern_interpretation (update_evar_val x m ρₑ) ρ (evar_open 0 x ϕ) = ∅.
  Proof.
    intros x.
    rewrite -> pattern_interpretation_ex_simpl. simpl.
    rewrite -> set_eq_subseteq.
    split.
    - intros [H1 _] m.
      rewrite -> elem_of_subseteq in H1.
      unfold propset_fa_union in H1.
      setoid_rewrite -> elem_of_PropSet in H1.
      rewrite -> set_eq_subseteq.
      split.
      2: { apply empty_subseteq. }
      rewrite -> elem_of_subseteq.
      intros x0.
      intros Contra.
      specialize (H1 x0). apply H1.
      exists m. assumption.
    - intros H.
      split.
      2: { apply empty_subseteq. }
      rewrite -> elem_of_subseteq.
      intros x0.
      intros Contra.
      unfold propset_fa_union in Contra.
      rewrite -> elem_of_PropSet in Contra.
      destruct Contra as [m Contra].
      rewrite H in Contra.
      exact Contra.
  Qed.


  (* Theory,axiom ref. snapshot: Definition 5 *)

  
  Definition satisfies_model (m : Model) (phi : Pattern) : Prop :=
    forall (evar_val : evar -> Domain m) (svar_val : svar -> Power (Domain m)),
      pattern_interpretation (m := m) evar_val svar_val phi = Full.

  Definition satisfies_theory (m : Model) (theory : Theory)
    : Prop := forall axiom : Pattern, axiom ∈ theory -> (satisfies_model m axiom).

  (* TODO rename *)
  Definition satisfies (theory : Theory) (p: Pattern)
    : Prop := forall m : Model, (satisfies_theory m theory) -> (satisfies_model m p).

  Lemma satisfies_theory_iff_satisfies_named_axioms {Σ : Signature} NAs M:
    satisfies_theory M (theory_of_NamedAxioms NAs) <->
    forall (n : NAName NAs), satisfies_model M (NAAxiom n).
  Proof.
    split.
    - intros. unfold satisfies_theory in H.
      specialize (H (NAAxiom n)). apply H.
      unfold In. unfold theory_of_NamedAxioms.
      exists n. auto.
    - intros H.
      intros ax Hax.
      unfold In in Hax.
      unfold theory_of_NamedAxioms in Hax.
      destruct Hax as [axname Haxname].
      subst ax.
      apply H.
  Qed.

  Lemma satisfies_theory_subseteq M Γ₁ Γ₂:
    Γ₁ ⊆ Γ₂ ->
    satisfies_theory M Γ₂ ->
    satisfies_theory M Γ₁.
  Proof.
    unfold satisfies_theory.
    set_solver by fail.
  Qed.


  (* theory predicate *)
  Definition T_predicate Γ ϕ := forall M, satisfies_theory M Γ -> M_predicate M ϕ.

  Hint Extern 4 (M_predicate _ (evar_open _ _ _)) => unfold evar_open; rewrite !simpl_bevar_subst' : core.
  Hint Extern 4 (T_predicate _ (evar_open _ _ _)) => unfold evar_open; rewrite !simpl_bevar_subst' : core.
  Hint Extern 4 (M_predicate _ (svar_open _ _ _)) => unfold svar_open; rewrite !simpl_bsvar_subst' : core.
  Hint Extern 4 (T_predicate _ (svar_open _ _ _)) => unfold svar_open; rewrite !simpl_bsvar_subst' : core.
  
  Lemma T_predicate_impl_M_predicate M Γ ϕ:
    satisfies_theory M Γ -> T_predicate Γ ϕ -> M_predicate M ϕ.
  Proof.
    unfold T_predicate. auto.
  Qed.

  Hint Resolve T_predicate_impl_M_predicate : core.

  Lemma T_predicate_impl Γ ϕ₁ ϕ₂ : T_predicate Γ ϕ₁ -> T_predicate Γ ϕ₂ -> T_predicate Γ (patt_imp ϕ₁ ϕ₂).
  Proof.
    unfold T_predicate.
    intros.
    auto using M_predicate_impl.
  Qed.

  Hint Resolve T_predicate_impl : core.

  Lemma T_predicate_bot Γ : T_predicate Γ patt_bott.
  Proof.
    unfold T_predicate.
    intros.
    auto using M_predicate_bott.
  Qed.

  Hint Resolve T_predicate_bot : core.

  (* TODO: top iff exists forall *)


  (* If phi1 \subseteq phi2, then U_x phi1 \subseteq U_x phi2 *)
  Lemma pattern_interpretation_subset_union M x phi1 phi2 :
    (forall evar_val svar_val,
        (@pattern_interpretation M evar_val svar_val phi1)
          ⊆ (pattern_interpretation evar_val svar_val phi2)
    )
    -> (forall evar_val svar_val,
                    (propset_fa_union (fun e => pattern_interpretation (update_evar_val x e evar_val)
                                                               svar_val
                                                               phi1))
                    ⊆
                    (propset_fa_union (fun e => @pattern_interpretation M (update_evar_val x e evar_val)
                                                               svar_val
                                                               phi2))
       ).
  Proof.
    intros H. induction phi1; intros; apply propset_fa_union_included; auto.
  Qed.

  (* pattern_interpretation unchanged when using fresh element varaiable *)
  Lemma Private_pattern_interpretation_free_evar_independent M ρₑ ρ x v sz ϕ:
    size ϕ <= sz ->
    evar_is_fresh_in x ϕ ->
    @pattern_interpretation M (update_evar_val x v ρₑ) ρ ϕ
    = @pattern_interpretation M ρₑ ρ ϕ.
  Proof.
    generalize dependent v. generalize dependent x.
    generalize dependent ρ. generalize dependent ρₑ. generalize dependent ϕ.
    induction sz; intros ϕ ρₑ ρ x v; destruct ϕ; simpl; intros Hsz Hnotin; unfold evar_is_fresh_in in Hnotin;
      simpl in Hnotin.
    - repeat rewrite -> pattern_interpretation_free_evar_simpl.
      apply f_equal. unfold update_evar_val.
      destruct (decide (x = x0)); simpl.
      + subst.
        apply not_elem_of_singleton_1 in Hnotin.
        contradiction.
      + reflexivity.
    - repeat rewrite -> pattern_interpretation_free_svar_simpl.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_bound_evar_simpl.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_bound_svar_simpl.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_sym_simpl.
      reflexivity.
    - lia.
    - repeat rewrite -> pattern_interpretation_bott_simpl.
      reflexivity.
    - lia.
    - lia.
    - lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - repeat rewrite -> pattern_interpretation_app_simpl.
      simpl in Hnotin.
      apply not_elem_of_union in Hnotin. destruct Hnotin as [Hnotin1 Hnotin2].
      rewrite -> IHsz. 3: apply Hnotin1. 2: lia.
      rewrite -> IHsz. 3: apply Hnotin2. 2: lia.
      reflexivity.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - repeat rewrite -> pattern_interpretation_imp_simpl.
      simpl in Hnotin.
      apply not_elem_of_union in Hnotin. destruct Hnotin as [Hnotin1 Hnotin2].
      rewrite -> IHsz. 3: apply Hnotin1. 2: lia.
      rewrite -> IHsz. 3: apply Hnotin2. 2: lia.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_ex_simpl.
      simpl.
      
      apply f_equal. apply functional_extensionality. intros e.
      destruct (decide ((fresh_evar ϕ) = x)).
      + rewrite -> e0. rewrite -> update_evar_val_shadow. reflexivity.
      + rewrite -> update_evar_val_comm. 2: apply n.
        rewrite -> IHsz.
        3: { intros Contra.
             pose proof (Hfeeo := @free_evars_evar_open signature ϕ (fresh_evar ϕ) 0).
             rewrite -> elem_of_subseteq in Hfeeo.
             specialize (Hfeeo x Contra).
             apply elem_of_union in Hfeeo.
             destruct Hfeeo as [H|H].
             * apply elem_of_singleton_1 in H. symmetry in H. contradiction.
             * contradiction.
        }
        2: { rewrite <- evar_open_size. lia. }
        reflexivity.
    - repeat rewrite -> pattern_interpretation_mu_simpl. simpl.
      
      apply f_equal. apply functional_extensionality.
      intros e.
      rewrite -> IHsz.
      3: { intros Contra.
           rewrite -> free_evars_svar_open in Contra.
           contradiction.
      }
      2: {
        rewrite <- svar_open_size. lia.
      }
      reflexivity.
  Qed.

  Lemma pattern_interpretation_free_evar_independent M ρₑ ρₛ x v ϕ:
    evar_is_fresh_in x ϕ ->
    @pattern_interpretation M (update_evar_val x v ρₑ) ρₛ ϕ
    = @pattern_interpretation M ρₑ ρₛ ϕ.
  Proof.
    intros.
    apply Private_pattern_interpretation_free_evar_independent with (sz := size ϕ).
    * lia.
    * assumption.
  Qed.

  (* pattern_interpretation unchanged when using fresh set varaiable *)
  Lemma Private_pattern_interpretation_free_svar_independent M ρₑ ρₛ X S sz ϕ:
    size ϕ <= sz ->
    svar_is_fresh_in X ϕ ->
    @pattern_interpretation M ρₑ (update_svar_val X S ρₛ) ϕ
    = @pattern_interpretation M ρₑ ρₛ ϕ.
  Proof.
    generalize dependent S. generalize dependent X.
    generalize dependent ρₛ. generalize dependent ρₑ. generalize dependent ϕ.
    induction sz; intros ϕ ρₑ ρₛ X S; destruct ϕ; simpl; intros Hsz Hnotin; unfold svar_is_fresh_in in Hnotin;
      simpl in Hnotin.
    - repeat rewrite -> pattern_interpretation_free_evar_simpl.
      reflexivity.
    - repeat rewrite pattern_interpretation_free_svar_simpl.
      unfold update_svar_val.
      destruct (decide (X = x)); simpl.
      + subst.
        apply not_elem_of_singleton_1 in Hnotin.
        contradiction.
      + reflexivity.
    - repeat rewrite -> pattern_interpretation_free_svar_simpl.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_bound_evar_simpl.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_bound_svar_simpl.
      reflexivity.
    - lia.
    - repeat rewrite -> pattern_interpretation_bott_simpl.
      reflexivity.
    - lia.
    - lia.
    - lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - repeat rewrite -> pattern_interpretation_app_simpl.
      simpl in Hnotin.
      apply not_elem_of_union in Hnotin. destruct Hnotin as [Hnotin1 Hnotin2].
      rewrite -> IHsz. 3: apply Hnotin1. 2: lia.
      rewrite -> IHsz. 3: apply Hnotin2. 2: lia.
      reflexivity.
    - apply IHsz. 2: { simpl. apply Hnotin. } simpl. lia.
    - repeat rewrite -> pattern_interpretation_imp_simpl.
      simpl in Hnotin.
      apply not_elem_of_union in Hnotin. destruct Hnotin as [Hnotin1 Hnotin2].
      rewrite -> IHsz. 3: apply Hnotin1. 2: lia.
      rewrite -> IHsz. 3: apply Hnotin2. 2: lia.
      reflexivity.
    - repeat rewrite -> pattern_interpretation_ex_simpl.
      simpl.
      apply f_equal. apply functional_extensionality. intros e.
      rewrite IHsz.
      { rewrite -evar_open_size. lia. }
      { apply svar_fresh_evar_open. apply Hnotin. }
      reflexivity.
    - repeat rewrite pattern_interpretation_mu_simpl. simpl.
      apply f_equal. apply functional_extensionality.
      intros e.
      destruct (decide ((fresh_svar ϕ) = X)).
      + rewrite e0. rewrite update_svar_val_shadow. reflexivity.
      + rewrite update_svar_val_comm.
        { apply n.  }
        rewrite IHsz.
        { rewrite -svar_open_size. lia.  }

        { intros Contra.
          pose proof (Hfeeo := @free_svars_svar_open signature ϕ (fresh_svar ϕ) 0).
          rewrite -> elem_of_subseteq in Hfeeo.
          specialize (Hfeeo X Contra).
          apply elem_of_union in Hfeeo.
          destruct Hfeeo as [H|H].
          * apply elem_of_singleton_1 in H. symmetry in H. contradiction.
          * contradiction.
        }
        reflexivity.
  Qed.

  Lemma pattern_interpretation_free_svar_independent M ρₑ ρ X S ϕ:
    svar_is_fresh_in X ϕ ->
    @pattern_interpretation M ρₑ (update_svar_val X S ρ) ϕ
    = @pattern_interpretation M ρₑ ρ ϕ.
  Proof.
    intros.
    apply Private_pattern_interpretation_free_svar_independent with (sz := size ϕ).
    * lia.
    * assumption.
  Qed.

  (* Can change updated/opened fresh variable variable *)
  Lemma Private_interpretation_fresh_var_open M sz ϕ dbi ρₑ ρ:
    size ϕ <= sz ->
    (
      forall X Y S,
        svar_is_fresh_in X ϕ ->
        svar_is_fresh_in Y ϕ ->
        @pattern_interpretation M ρₑ (update_svar_val X S ρ) (svar_open dbi X ϕ)
        = @pattern_interpretation M ρₑ (update_svar_val Y S ρ) (svar_open dbi Y ϕ)
    ) /\
    (
      forall x y c,
        evar_is_fresh_in x ϕ ->
        evar_is_fresh_in y ϕ ->
        @pattern_interpretation M (update_evar_val x c ρₑ) ρ (evar_open dbi x ϕ)
        = @pattern_interpretation M (update_evar_val y c ρₑ) ρ (evar_open dbi y ϕ)
    )
  .
  Proof.
    move: ϕ dbi ρₑ ρ.
    induction sz.
    - move=> ϕ dbi ρₑ ρ Hsz.
      split.
      {
        (* base case - svar *)
        move=> X Y S HfrX HfrY.
        destruct ϕ; simpl in Hsz; try lia.
        + rewrite 2!pattern_interpretation_free_evar_simpl. reflexivity.
        + rewrite 2!pattern_interpretation_free_svar_simpl.
          unfold svar_is_fresh_in in HfrX, HfrY. simpl in HfrX, HfrY.
          apply not_elem_of_singleton_1 in HfrX.
          apply not_elem_of_singleton_1 in HfrY.
          unfold update_svar_val.
          destruct (decide (X = x)),(decide (Y = x)); simpl; try contradiction.
          reflexivity.
        + rewrite 2!pattern_interpretation_bound_evar_simpl. reflexivity.
        + unfold svar_open. simpl. case_match.
          * rewrite 2!pattern_interpretation_bound_svar_simpl.
            reflexivity.
          * rewrite 2!pattern_interpretation_free_svar_simpl.
            rewrite 2!update_svar_val_same. reflexivity.
          * rewrite 2!pattern_interpretation_bound_svar_simpl.
            reflexivity.
        + rewrite 2!pattern_interpretation_sym_simpl.
          reflexivity.
        + rewrite 2!pattern_interpretation_bott_simpl.
          reflexivity.
      }
      {
        (* base case - evar *)
        move=> x y c Hfrx Hfry.
        destruct ϕ; simpl in Hsz; try lia.
        + rewrite 2!pattern_interpretation_free_evar_simpl.
          unfold evar_is_fresh_in in Hfrx, Hfry. simpl in Hfrx, Hfry.
          apply not_elem_of_singleton_1 in Hfrx.
          apply not_elem_of_singleton_1 in Hfry.
          apply f_equal. unfold update_evar_val.
          destruct (decide (x = x0)),(decide (y = x0)); simpl; try contradiction.
          reflexivity.
        + rewrite 2!pattern_interpretation_free_svar_simpl.
          reflexivity.
        + unfold evar_open. simpl. case_match.
          * rewrite 2!pattern_interpretation_bound_evar_simpl.
            reflexivity.
          * rewrite 2!pattern_interpretation_free_evar_simpl.
            rewrite 2!update_evar_val_same. reflexivity.
          * rewrite 2!pattern_interpretation_bound_evar_simpl.
            reflexivity.
        + rewrite 2!pattern_interpretation_bound_svar_simpl. reflexivity.
        + rewrite 2!pattern_interpretation_sym_simpl.
          reflexivity.
        + rewrite 2!pattern_interpretation_bott_simpl.
          reflexivity.
      }
    - move=> ϕ dbi ρₑ ρ Hsz.
      split.
      {
        (* inductive case - svar *)
        move=> X Y S HfrX HfrY.
        destruct ϕ; simpl in Hsz.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite 2!pattern_interpretation_app_simpl. fold svar_open.
          rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: rewrite (proj1 (IHsz _ _ _ _ _) X Y). lia.
          eapply svar_is_fresh_in_app_l. apply HfrX.
          eapply svar_is_fresh_in_app_l. apply HfrY.
          lia.
          eapply svar_is_fresh_in_app_r. apply HfrX.
          eapply svar_is_fresh_in_app_r. apply HfrY.
          reflexivity.
        + rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite 2!pattern_interpretation_imp_simpl. fold svar_open.
          rewrite (proj1 (IHsz _ _ _ _ _) X Y). 4: rewrite (proj1 (IHsz _ _ _ _ _) X Y). lia.
          eapply svar_is_fresh_in_app_l. apply HfrX.
          eapply svar_is_fresh_in_app_l. apply HfrY.
          lia.
          eapply svar_is_fresh_in_app_r. apply HfrX.
          eapply svar_is_fresh_in_app_r. apply HfrY.
          reflexivity.
        + rewrite 2!pattern_interpretation_ex_simpl. fold svar_open. simpl.
          apply f_equal. apply functional_extensionality. intros e.
          rewrite 2!svar_open_evar_open_comm.
          rewrite (proj1 (IHsz _ _ _ _ _) X Y). rewrite -evar_open_size. lia.
          apply svar_is_fresh_in_exists in HfrX.
          apply svar_is_fresh_in_exists in HfrY.
          apply svar_fresh_evar_open. apply HfrX.
          apply svar_fresh_evar_open. apply HfrY.
          rewrite -2!svar_open_evar_open_comm.
          rewrite (proj2 (IHsz _ _ _ _ _) _ (fresh_evar (svar_open dbi Y ϕ))). rewrite -svar_open_size. lia.
          rewrite fresh_evar_svar_open.
          apply evar_fresh_svar_open. apply set_evar_fresh_is_fresh.
          apply set_evar_fresh_is_fresh.
          reflexivity.
        + rewrite 2!svar_open_mu.
          rewrite 2!pattern_interpretation_mu_simpl. fold svar_open. simpl.
          apply f_equal. apply functional_extensionality.
          intros S'.

          remember (fresh_svar (svar_open (Datatypes.S dbi) X ϕ)) as X'.
          remember (fresh_svar (svar_open (Datatypes.S dbi) Y ϕ)) as Y'.
          remember ((@singleton svar (@SVarSet signature) _ X)
                      ∪ ((singleton Y)
                           ∪ ((singleton X')
                                ∪ ((singleton Y')
                                     ∪ ((free_svars (svar_open (Datatypes.S dbi) X ϕ))
                                          ∪ (free_svars (svar_open (Datatypes.S dbi) Y ϕ)
                                                        ∪ (free_svars ϕ))))))) as B.
          remember (svar_fresh (elements B)) as fresh3.
          assert(HB: fresh3 ∉ B).
          {
            subst. apply set_svar_fresh_is_fresh'.
          }

          remember (free_svars (svar_open (Datatypes.S dbi) Y ϕ) ∪ (free_svars ϕ)) as B0.
          remember ((free_svars (svar_open (Datatypes.S dbi) X ϕ)) ∪ B0) as B1.
          remember ({[Y']} ∪ B1) as B2.
          remember ({[X']} ∪ B2) as B3.
          remember ({[Y]} ∪ B3) as B4.
          pose proof (i := not_elem_of_union fresh3 {[X]} B4).
          pose proof (i0 := not_elem_of_union fresh3 {[Y]} B3).
          pose proof (i1 := not_elem_of_union fresh3 {[X']} B2).
          pose proof (i2 := not_elem_of_union fresh3 {[Y']} B1).
          pose proof (i3 := not_elem_of_union fresh3 
                                              (free_svars (svar_open (Datatypes.S dbi) X ϕ)) 
                                              B0).
          subst B0. subst B1. subst B2. subst B3. subst B4. subst B.
          
          apply i in HB. clear i. destruct HB as [Hneqfr1 HB].        
          apply not_elem_of_singleton_1 in Hneqfr1.

          apply i0 in HB. clear i0. destruct HB as [Hneqfr2 HB].
          apply not_elem_of_singleton_1 in Hneqfr2.

          apply i1 in HB. clear i1. destruct HB as [Hneqfr11 HB].
          apply not_elem_of_singleton_1 in Hneqfr11.

          apply i2 in HB. clear i2. destruct HB as [Hneqfr22 HB].
          apply not_elem_of_singleton_1 in Hneqfr22.

          apply i3 in HB. clear i3. destruct HB as [HnotinFree1 HB].
          apply not_elem_of_union in HB.
          destruct HB as [HnotinFree2 HnotinFree].
          fold bsvar_subst.
          
          rewrite (proj1 (IHsz _ _ _ _ _) X' fresh3). rewrite -svar_open_size. lia.
          rewrite HeqX'. apply set_svar_fresh_is_fresh. unfold svar_is_fresh_in. apply HnotinFree1.
          rewrite (proj1 (IHsz _ _ _ _ _) Y' fresh3). rewrite -svar_open_size. lia.
          rewrite HeqY'. apply set_svar_fresh_is_fresh. unfold svar_is_fresh_in. apply HnotinFree2.
          rewrite (@svar_open_comm_higher signature 0 (Datatypes.S dbi) _ fresh3 X ϕ). lia.
          rewrite (@svar_open_comm_higher signature 0 (Datatypes.S dbi) _ fresh3 Y ϕ). lia.
          replace (pred (Datatypes.S dbi)) with dbi by lia.
          rewrite (@update_svar_val_comm _ fresh3 X). apply Hneqfr1.
          rewrite (@update_svar_val_comm _ fresh3 Y). apply Hneqfr2.
          apply svar_is_fresh_in_exists in HfrX.
          apply svar_is_fresh_in_exists in HfrY.
          rewrite (proj1 (IHsz _ _ _ _ _) X Y). rewrite -svar_open_size. lia.
          unfold svar_is_fresh_in.
          apply svar_open_fresh_notin.
          apply HfrX. apply HnotinFree. intros Contra. symmetry in Contra. contradiction.
          apply svar_open_fresh_notin.
          apply HfrY. apply HnotinFree. intros Contra. symmetry in Contra. contradiction.
          reflexivity.
      }
      {
        (* inductive case - evar *)
        move=> x y c Hfrx Hfry.
        destruct ϕ; simpl in Hsz.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite 2!pattern_interpretation_app_simpl. fold evar_open.
          rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: rewrite (proj2 (IHsz _ _ _ _ _) x y). lia.
          eapply evar_is_fresh_in_app_l. apply Hfrx.
          eapply evar_is_fresh_in_app_l. apply Hfry.
          lia.
          eapply evar_is_fresh_in_app_r. apply Hfrx.
          eapply evar_is_fresh_in_app_r. apply Hfry.
          reflexivity.
        + rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: reflexivity. 3,2: auto. simpl. lia.
        + rewrite 2!pattern_interpretation_imp_simpl. fold evar_open.
          rewrite (proj2 (IHsz _ _ _ _ _) x y). 4: rewrite (proj2 (IHsz _ _ _ _ _) x y). lia.
          eapply evar_is_fresh_in_app_l. apply Hfrx.
          eapply evar_is_fresh_in_app_l. apply Hfry.
          lia.
          eapply evar_is_fresh_in_app_r. apply Hfrx.
          eapply evar_is_fresh_in_app_r. apply Hfry.
          reflexivity.
        + do 2 rewrite evar_open_exists.
          rewrite 2!pattern_interpretation_ex_simpl. fold evar_open. simpl.
          apply f_equal. apply functional_extensionality. intros e.
          remember (fresh_evar (evar_open (Datatypes.S dbi) x ϕ)) as x'.
          remember (fresh_evar (evar_open (Datatypes.S dbi) y ϕ)) as y'.
          remember ((@singleton evar (@EVarSet signature) _ x)
                      ∪ ((singleton y)
                           ∪ ((singleton x')
                                ∪ ((singleton y')
                                     ∪ ((free_evars (evar_open (Datatypes.S dbi) x ϕ))
                                          ∪ (free_evars (evar_open (Datatypes.S dbi) y ϕ)
                                                        ∪ (free_evars ϕ))))))) as B.
          remember (evar_fresh (elements B)) as fresh3.
          assert(HB: fresh3 ∉ B).
          {
            subst. apply set_evar_fresh_is_fresh'.
          }

          remember (free_evars (evar_open (Datatypes.S dbi) y ϕ) ∪ (free_evars ϕ)) as B0.
          remember ((free_evars (evar_open (Datatypes.S dbi) x ϕ)) ∪ B0) as B1.
          remember ({[y']} ∪ B1) as B2.
          remember ({[x']} ∪ B2) as B3.
          remember ({[y]} ∪ B3) as B4.
          pose proof (i := not_elem_of_union fresh3 {[x]} B4).
          pose proof (i0 := not_elem_of_union fresh3 {[y]} B3).
          pose proof (i1 := not_elem_of_union fresh3 {[x']} B2).
          pose proof (i2 := not_elem_of_union fresh3 {[y']} B1).
          pose proof (i3 := not_elem_of_union fresh3 
                                              (free_evars (evar_open (Datatypes.S dbi) x ϕ)) 
                                              B0).
          subst B0. subst B1. subst B2. subst B3. subst B4. subst B.
          
          apply i in HB. clear i. destruct HB as [Hneqfr1 HB].        
          apply not_elem_of_singleton_1 in Hneqfr1.

          apply i0 in HB. clear i0. destruct HB as [Hneqfr2 HB].
          apply not_elem_of_singleton_1 in Hneqfr2.

          apply i1 in HB. clear i1. destruct HB as [Hneqfr11 HB].
          apply not_elem_of_singleton_1 in Hneqfr11.

          apply i2 in HB. clear i2. destruct HB as [Hneqfr22 HB].
          apply not_elem_of_singleton_1 in Hneqfr22.

          apply i3 in HB. clear i3. destruct HB as [HnotinFree1 HB].
          apply not_elem_of_union in HB.
          destruct HB as [HnotinFree2 HnotinFree].
          rewrite (proj2 (IHsz _ _ _ _ _) x' fresh3). rewrite -evar_open_size. lia.
          rewrite Heqx'. apply set_evar_fresh_is_fresh. unfold evar_is_fresh_in. apply HnotinFree1.
          rewrite (proj2 (IHsz _ _ _ _ _) y' fresh3). rewrite -evar_open_size. lia.
          rewrite Heqy'. apply set_evar_fresh_is_fresh. unfold evar_is_fresh_in. apply HnotinFree2.
          rewrite (@evar_open_comm_higher signature 0 (Datatypes.S dbi) _ fresh3 x ϕ). lia.
          rewrite (@evar_open_comm_higher signature 0 (Datatypes.S dbi) _ fresh3 y ϕ). lia.
          replace (pred (Datatypes.S dbi)) with dbi by lia.
          rewrite (@update_evar_val_comm _ fresh3 x). apply Hneqfr1.
          rewrite (@update_evar_val_comm _ fresh3 y). apply Hneqfr2.
          apply evar_is_fresh_in_exists in Hfrx.
          apply evar_is_fresh_in_exists in Hfry.
          rewrite (proj2 (IHsz _ _ _ _ _) x y). rewrite -evar_open_size. lia.
          unfold evar_is_fresh_in.
          apply evar_open_fresh_notin.
          apply Hfrx. apply HnotinFree. intros Contra. symmetry in Contra. contradiction.
          apply evar_open_fresh_notin.
          apply Hfry. apply HnotinFree. intros Contra. symmetry in Contra. contradiction.
          reflexivity.
        + rewrite 2!pattern_interpretation_mu_simpl. fold evar_open. simpl.
          apply f_equal. apply functional_extensionality.
          intros S'.
          rewrite -2!svar_open_evar_open_comm.
          rewrite (proj2 (IHsz _ _ _ _ _) x y). rewrite -svar_open_size. lia.
          apply evar_is_fresh_in_mu in Hfrx.
          apply evar_is_fresh_in_mu in Hfry.
          apply evar_fresh_svar_open. apply Hfrx.
          apply evar_fresh_svar_open. apply Hfry.
          rewrite 2!svar_open_evar_open_comm.
          rewrite (proj1 (IHsz _ _ _ _ _) _ (fresh_svar (evar_open dbi y ϕ))). rewrite -evar_open_size. lia.
          apply svar_fresh_evar_open.
          rewrite fresh_svar_evar_open. apply set_svar_fresh_is_fresh.
          apply set_svar_fresh_is_fresh.
          reflexivity.
      }
  Qed.


  Lemma interpretation_fresh_evar_open M ϕ x y c dbi ρₑ ρ:
    evar_is_fresh_in x ϕ ->
    evar_is_fresh_in y ϕ ->
    @pattern_interpretation M (update_evar_val x c ρₑ) ρ (evar_open dbi x ϕ)
    = @pattern_interpretation M (update_evar_val y c ρₑ) ρ (evar_open dbi y ϕ).
  Proof.
    move=> Hfrx Hfry.
    eapply (proj2 (@Private_interpretation_fresh_var_open M (size ϕ) ϕ dbi ρₑ ρ _) x y c); assumption.
    Unshelve. lia.
  Qed.

  Lemma interpretation_fresh_svar_open M ϕ X Y S dbi ρₑ ρ:
    svar_is_fresh_in X ϕ ->
    svar_is_fresh_in Y ϕ ->
    @pattern_interpretation M ρₑ (update_svar_val X S ρ) (svar_open dbi X ϕ)
    = @pattern_interpretation M ρₑ (update_svar_val Y S ρ) (svar_open dbi Y ϕ).
  Proof.
    move=> HfrX HfrY.
    eapply (proj1 (@Private_interpretation_fresh_var_open M (size ϕ) ϕ dbi ρₑ ρ _) X Y S); assumption.
    Unshelve. lia.
  Qed.

  (* There are two ways how to plug a pattern phi2 into a pattern phi1:
   either substitute it for some variable,
   or evaluate phi2 first and then evaluate phi1 with valuation updated to the result of phi2
  *)
  Lemma Private_plugging_patterns : forall (sz : nat) (dbi : db_index) (M : Model) (phi1 phi2 : Pattern),
      size phi1 <= sz -> forall (evar_val : EVarVal)
                                (svar_val : SVarVal) (X : svar),
        well_formed_closed phi2 -> well_formed_closed_mu_aux phi1 (S dbi) ->
        ~ elem_of X (free_svars phi1) ->
        @pattern_interpretation M evar_val svar_val (bsvar_subst phi1 phi2 dbi)
        = @pattern_interpretation M evar_val
                                  (update_svar_val X (@pattern_interpretation M evar_val svar_val phi2) svar_val)
                                  (svar_open dbi X phi1).
  Proof.
    induction sz; intros dbi M phi1 phi2 Hsz evar_val svar_val X Hwfc2 Hwfphi1 H.
    - (* sz == 0 *)
      destruct phi1; simpl in Hsz; simpl.
      + (* free_evar *)
        repeat rewrite -> pattern_interpretation_free_evar_simpl. auto.
      + (* free_svar *)
        unfold svar_open. simpl.
        do 2 rewrite -> pattern_interpretation_free_svar_simpl.
        unfold update_svar_val. destruct (decide (X = x)).
        * simpl in H. simpl. unfold not in H. exfalso. apply H.
          apply elem_of_singleton_2. auto.
        * auto.
      + (* bound_evar *)
        rewrite 2!pattern_interpretation_bound_evar_simpl.
        reflexivity.
      + (* bound_svar *)
        unfold svar_open. simpl.  case_match; simpl.
        * repeat rewrite -> pattern_interpretation_bound_svar_simpl; auto.
        * rewrite pattern_interpretation_free_svar_simpl. unfold update_svar_val.
          destruct (decide (X = X)). auto. contradiction.
        * repeat rewrite -> pattern_interpretation_bound_svar_simpl; auto.
      + (* sym *)
        simpl. repeat rewrite -> pattern_interpretation_sym_simpl; auto.
      + (* app *)
        lia.
      + (* bot *)
        simpl. repeat rewrite pattern_interpretation_bott_simpl; auto.
      + (* impl *)
        lia.
      + (* ex *)
        lia.
      + (* mu *)
        lia.
    - (* sz = S sz' *)
      destruct phi1; simpl.
      (* HERE we duplicate some of the effort. I do not like it. *)
      + (* free_evar *)
        repeat rewrite pattern_interpretation_free_evar_simpl. auto.
      + (* free_svar *)
        unfold svar_open. simpl.
        do 2 rewrite -> pattern_interpretation_free_svar_simpl.
        unfold update_svar_val. destruct (decide (X = x)).
        * simpl in H. simpl. unfold not in H. exfalso. apply H.
          apply elem_of_singleton_2. auto.
        * auto.
      + (* bound_evar *)
        rewrite !pattern_interpretation_bound_evar_simpl. reflexivity.
      + (* bound_svar *)
        unfold svar_open. simpl. case_match.
        * repeat rewrite -> pattern_interpretation_bound_evar_simpl; auto.
        * rewrite pattern_interpretation_free_svar_simpl. unfold update_svar_val.
          destruct (decide (X = X)). simpl. auto. contradiction.
        * repeat rewrite -> pattern_interpretation_bound_svar_simpl; auto.
      + (* sym *)
        simpl. repeat rewrite -> pattern_interpretation_sym_simpl; auto.
      (* HERE the duplication ends *)
      + (* app *) unfold svar_open in *.
        simpl.
        simpl in H. apply not_elem_of_union in H. destruct H.
        do 2 rewrite -> pattern_interpretation_app_simpl.
        simpl in Hsz.
        rewrite <- (IHsz _ _ phi1_1), <- (IHsz _ _ phi1_2).
        * reflexivity.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwfphi1.
        * auto.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwfphi1.
        * auto.
      + (* Bot. Again, a duplication of the sz=0 case *)
        simpl. repeat rewrite pattern_interpretation_bott_simpl; auto.
      + (* imp *)
        unfold svar_open in *.
        simpl in Hsz. simpl in H. simpl.
        apply not_elem_of_union in H. destruct H.
        do 2 rewrite -> pattern_interpretation_imp_simpl.
        rewrite <- IHsz, <- IHsz.
        * reflexivity.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwfphi1.
        * auto.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwfphi1.
        * auto.

      + simpl in Hsz. simpl in H. unfold svar_open in *. simpl.
        do 2 rewrite -> pattern_interpretation_ex_simpl. simpl.
        apply propset_fa_union_same. intros c.

        (* x = fresh_evar phi1' *)
        (* y = evar_fresh (elements (free_evars phi1') U (free_evars phi2)) *)

        remember (bsvar_subst phi1 (patt_free_svar X) dbi) as phi1'.
        remember (fresh_evar phi1') as Xfr2'.
        remember (evar_fresh (elements (union (free_evars phi1') (free_evars phi2)))) as Xu.
        remember (update_svar_val X (pattern_interpretation evar_val svar_val phi2) svar_val) as svar_val2'.
        pose proof (Hfresh_subst := @interpretation_fresh_evar_open M phi1' Xfr2' Xu c 0 evar_val svar_val2').

        rewrite -> Hfresh_subst.
        2: { subst Xfr2'. apply set_evar_fresh_is_fresh. }
        2: { pose proof (Hfr := set_evar_fresh_is_fresh').
             specialize (Hfr (union (free_evars phi1') (free_evars phi2))).
             subst Xu.
             apply not_elem_of_union in Hfr. destruct Hfr as [Hfr _]. auto.
        }

        remember (update_evar_val (fresh_evar (bsvar_subst phi1 phi2 dbi)) c evar_val) as evar_val1'.
        remember (update_evar_val Xu c evar_val) as evar_val2'.
        rewrite -> evar_open_bsvar_subst. 2: auto.
        remember (fresh_evar (bsvar_subst phi1 phi2 dbi)) as Xfr1.

        (* dbi may or may not occur in phi1 *)
        remember (bsvar_occur phi1 dbi) as Hoc.
        move: HeqHoc.
        case: Hoc => HeqHoc.
        -- (* dbi ocurs in phi1 *)
          pose proof (HXfr1Fresh := @set_evar_fresh_is_fresh signature (bsvar_subst phi1 phi2 dbi)).
          rewrite <- HeqXfr1 in HXfr1Fresh.
          symmetry in HeqHoc.
          pose proof (Hsub := @bsvar_subst_contains_subformula signature phi1 phi2 dbi HeqHoc).
          pose proof (HXfr1Fresh2 := evar_fresh_in_subformula Hsub HXfr1Fresh).

          assert (Hinterp:
                    (pattern_interpretation evar_val1' svar_val phi2) =
                    (pattern_interpretation evar_val svar_val phi2)
                 ).
          { subst. apply pattern_interpretation_free_evar_independent. auto. }
          
          assert (He1e1':
                    (update_svar_val X (pattern_interpretation evar_val1' svar_val phi2) svar_val) =
                    (update_svar_val X (pattern_interpretation evar_val svar_val phi2) svar_val)
                 ).
          { congruence. }
          subst svar_val2'.
          rewrite <- He1e1'.
          subst phi1'.
          rewrite -> evar_open_bsvar_subst.

          assert (HXu: (Xfr1 = Xu)).
          { subst Xfr1. subst Xu. unfold fresh_evar.
            rewrite -> free_evars_bsvar_subst_eq.
            replace (bsvar_subst phi1 (patt_free_svar X) dbi) with
                    (svar_open dbi X phi1) by reflexivity.
            rewrite -> free_evars_svar_open. auto. auto.
          }
          rewrite -> HXu in *.
          assert (He1e2 : evar_val1' = evar_val2').
          { subst. auto. }
          rewrite <- He1e2.
          rewrite <- IHsz.
        * reflexivity.
        * rewrite <- evar_open_size. lia. 
        * auto.
        * now apply wfc_mu_aux_body_ex_imp1.
        * rewrite -> free_svars_evar_open. auto.
        * auto.
          -- (* dbi does not occur in phi1 *)
            pose proof (HeqHoc' := HeqHoc).
            rewrite -> bsvar_subst_not_occur.
            (* Now svar_open does nothing to phi1, since it does not contain dbi (see HeqHoc). *)
            symmetry in HeqHoc. simpl in Hwfphi1. apply wfc_mu_lower in Hwfphi1; auto.
            apply svar_open_not_occur with (x:=X) in Hwfphi1 as HWF.
            (* X is not free in phi1, so the fact that in svar_val2' it is updated to some 
           value is irrelevant. *)
            assert (Hpi: pattern_interpretation evar_val2' svar_val2' (evar_open 0 Xu phi1')
                         = pattern_interpretation evar_val2' svar_val (evar_open 0 Xu phi1')).
            { subst svar_val2'. apply pattern_interpretation_free_svar_independent.
              unfold svar_is_fresh_in. rewrite -> free_svars_evar_open. subst phi1'.
              replace (bsvar_subst phi1 (patt_free_svar X) dbi) with
                      (svar_open dbi X phi1) by reflexivity.
              rewrite -> HWF. auto.
            }
            rewrite -> Hpi. subst phi1'. unfold svar_open in HWF. rewrite -> HWF.
            subst evar_val1'. subst evar_val2'.
            rewrite -> interpretation_fresh_evar_open with (y := Xu).
            reflexivity.
            { subst Xfr1.
              symmetry in HeqHoc'.
              pose proof (Hsubst := @bsvar_subst_not_occur _ dbi phi2 _ Hwfphi1).
              rewrite Hsubst. auto.
            }
            { pose proof (Hfr := set_evar_fresh_is_fresh').
              specialize (Hfr (union (free_evars (svar_open dbi X phi1)) (free_evars phi2))).
              subst Xu.
              apply not_elem_of_union in Hfr. destruct Hfr as [Hfr _].
              rewrite free_evars_svar_open in Hfr.
              rewrite free_evars_svar_open. auto.
            }
            {
              apply wfc_mu_aux_body_ex_imp1. apply wfc_mu_lower in Hwfphi1; auto.
            }

      + (* Mu case *)
        rewrite svar_open_mu.
        rewrite 2!pattern_interpretation_mu_simpl. simpl.
        apply f_equal. apply functional_extensionality. intros E.

        remember (bsvar_subst phi1 phi2 (S dbi)) as phi_subst.
        remember (union (union (union (union (union (free_svars phi_subst) (singleton (fresh_svar phi1))) (free_svars phi1)) (free_svars (svar_open (S dbi) X phi1))) (singleton X)) (free_svars phi2)) as B.

        remember (svar_fresh (elements B)) as Y.
        assert (Hfreshy: Y <> fresh_svar phi1).
        { solve_fresh_svar_neq. }

        assert (Hfreshy': svar_is_fresh_in Y phi1).
        {
          subst.
          eapply svar_is_fresh_in_richer'.
          2: apply set_svar_fresh_is_fresh'.
          solve_free_svars_inclusion 5.
        }

        assert (Hfreshy'': svar_is_fresh_in Y (svar_open (S dbi) X phi1)).
        {
          subst.
          eapply svar_is_fresh_in_richer'.
          2: apply set_svar_fresh_is_fresh'.
          solve_free_svars_inclusion 5.
        }

        assert (Hfreshy''': Y <> X).
        { solve_fresh_svar_neq. }

        assert (Hfreshy'''': svar_is_fresh_in Y phi2).
        {
          subst.
          eapply svar_is_fresh_in_richer'.
          2: apply set_svar_fresh_is_fresh'.
          solve_free_svars_inclusion 5.
        }

        assert (Hfreshy5: svar_is_fresh_in Y (bsvar_subst phi1 phi2 (S dbi))).
        {
          subst.
          eapply svar_is_fresh_in_richer'.
          2: apply set_svar_fresh_is_fresh'.
          solve_free_svars_inclusion 7.
        }

        remember (bsvar_occur phi1 (S dbi)) as Hoc.
        destruct Hoc.
        --
          subst phi_subst.

          rewrite (@interpretation_fresh_svar_open _ _ ((fresh_svar (svar_open (S dbi) X phi1))) Y).
          { apply set_svar_fresh_is_fresh. }
          { apply Hfreshy''. }

          rewrite update_svar_val_comm.
          { apply Hfreshy'''. }
          rewrite svar_open_comm_higher.
          { lia. }
          replace (pred (S dbi)) with dbi by lia.

          remember ((update_svar_val Y E svar_val)) as svar_val'.

          assert (Hpieq: (pattern_interpretation evar_val svar_val' phi2) = (pattern_interpretation evar_val svar_val phi2)).
          { subst svar_val'.
            apply pattern_interpretation_free_svar_independent.
            apply Hfreshy''''.
          }
          rewrite -Hpieq.
          clear Hpieq.

          rewrite <- IHsz.
          4: { apply wfc_mu_aux_body_mu_imp3. lia. auto. }
          4: { apply svar_is_fresh_in_svar_open.
               apply not_eq_sym.
               apply Hfreshy'''.
               simpl in H.
               apply H.
          }
          3: { apply Hwfc2. }
          2: { rewrite -svar_open_size. simpl in Hsz. lia. }
          
          subst svar_val'.
          rewrite svar_open_bsvar_subst_higher.
          { apply Hwfc2. }
          { lia. }
          remember  (fresh_svar (bsvar_subst phi1 phi2 (S dbi))) as X'.

          rewrite -svar_open_bsvar_subst_higher.
          { apply Hwfc2. }
          { lia. }
          replace dbi with (pred (S dbi)) by lia.
          rewrite <- svar_open_bsvar_subst_higher.
          2: { apply Hwfc2. }
          2: { lia. }
          replace (pred (S dbi)) with dbi by lia.
          apply interpretation_fresh_svar_open.
          { subst X'. apply set_svar_fresh_is_fresh. }
          { apply Hfreshy5.  }
          
        --
          rewrite Heqphi_subst.
          rewrite bsvar_subst_not_occur. auto.
          rewrite bsvar_subst_not_occur in Heqphi_subst. all: auto.
          1-2: apply wfc_mu_lower; auto.

          rewrite -> interpretation_fresh_svar_open with (X := fresh_svar phi1) (Y := Y).
          2: { apply set_svar_fresh_is_fresh. }
          2: { subst.
               eapply svar_is_fresh_in_richer'.
               2: apply set_svar_fresh_is_fresh'.
               solve_free_svars_inclusion 5.
          }

          simpl in Hsz.
          
          subst phi_subst.

          rewrite -> svar_open_not_occur with (x := X)(n := S dbi).
          2: { apply wfc_mu_lower; auto. }

          destruct (decide (X = (fresh_svar phi1))).
          ++ subst X. rewrite update_svar_val_shadow.
             apply interpretation_fresh_svar_open.
             { apply Hfreshy'. }
             apply set_svar_fresh_is_fresh.
          ++ rewrite update_svar_val_comm.
             { apply not_eq_sym. apply n. }                              
             rewrite -> pattern_interpretation_free_svar_independent with (X:=X).
             2: { apply svar_is_fresh_in_svar_open. apply n.
                  simpl in H. apply H.
             }
             apply interpretation_fresh_svar_open.
             { apply Hfreshy'. }
             apply set_svar_fresh_is_fresh.
  Qed.

  Lemma set_substitution_lemma : forall (dbi : db_index) (M : Model) (phi1 phi2 : Pattern),
      forall (evar_val : EVarVal) (svar_val : SVarVal) (X : svar),
        well_formed_closed phi2 -> well_formed_closed_mu_aux phi1 (S dbi) ->
        ~ elem_of X (free_svars phi1) ->
        @pattern_interpretation M evar_val svar_val (bsvar_subst phi1 phi2 dbi)
        = @pattern_interpretation M evar_val
                                  (update_svar_val X (@pattern_interpretation M evar_val svar_val phi2) svar_val)
                                  (svar_open dbi X phi1).
  Proof.
    intros.
    apply Private_plugging_patterns with (sz := size phi1).
    lia. all: auto.
  Qed.

  Lemma Private_plugging_patterns_bevar_subst : forall (sz : nat) (dbi : db_index) (M : Model) (phi : Pattern) (y : evar),
      size phi <= sz -> forall (evar_val : EVarVal)
                               (svar_val : SVarVal) (x : evar),
        evar_is_fresh_in x phi -> well_formed_closed_ex_aux phi (S dbi) ->
        @pattern_interpretation M evar_val svar_val (bevar_subst phi (patt_free_evar y) dbi)
        = @pattern_interpretation M
                                  (update_evar_val x (evar_val y) evar_val)
                                  svar_val
                                  (evar_open dbi x phi).
  Proof.
    induction sz; intros dbi M phi y Hsz evar_val svar_val x H Hwf.
    - (* sz == 0 *)
      destruct phi; simpl in Hsz; simpl.
      + (* free_evar *)
        unfold evar_is_fresh_in in H.
        rewrite evar_open_free_evar.
        repeat rewrite -> pattern_interpretation_free_evar_simpl.
        unfold update_evar_val.
        destruct (decide (x = x0)).
        * simpl. unfold not in H. exfalso. apply H.
          apply elem_of_singleton_2. auto.
        * auto.
      + (* free_svar *)
        repeat rewrite -> pattern_interpretation_free_svar_simpl.
        auto.
      + (* bound_evar *)
        rewrite evar_open_bound_evar.
        case_match; subst.
        * auto.
        * do 2 rewrite pattern_interpretation_free_evar_simpl.
          unfold update_evar_val.
          case_match; auto. contradiction.
        * auto.
      + (* bound_svar *)
        rewrite 2!pattern_interpretation_bound_svar_simpl; auto.
      + (* sym *)
        simpl. repeat rewrite -> pattern_interpretation_sym_simpl; auto.
      + (* app *)
        lia.
      + (* bot *)
        simpl. repeat rewrite pattern_interpretation_bott_simpl; auto.
      + (* impl *)
        lia.
      + (* ex *)
        lia.
      + (* mu *)
        lia.
    - (* sz = S sz' *)
      destruct phi; simpl.
      (* HERE we duplicate some of the effort. I do not like it. *)
      + (* free_evar *)
        unfold evar_is_fresh_in in H. rewrite evar_open_free_evar.
        do 2 rewrite -> pattern_interpretation_free_evar_simpl.
        unfold update_evar_val.
        destruct (decide (x = x0)).
        * simpl. unfold not in H. exfalso. apply H.
          apply elem_of_singleton_2. auto.
        * auto.
      + (* free_svar *)
        repeat rewrite -> pattern_interpretation_free_svar_simpl.
        auto.
      + (* bound_evar *)
        rewrite evar_open_bound_evar.
        case_match.
        * auto.
        * repeat rewrite pattern_interpretation_free_evar_simpl. unfold update_evar_val.
          destruct (decide (x = x)). auto. contradiction.
        * auto.
      + (* bound_svar *)
        rewrite 2!pattern_interpretation_bound_svar_simpl; auto.
      + (* sym *)
        simpl. repeat rewrite -> pattern_interpretation_sym_simpl; auto.
      (* HERE the duplication ends *)
      + (* app *)
        rewrite evar_open_app.
        unfold evar_is_fresh_in in H. simpl in H. apply not_elem_of_union in H. destruct H.
        repeat rewrite -> pattern_interpretation_app_simpl.
        simpl in Hsz.
        repeat rewrite <- IHsz.
        * reflexivity.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwf.
        * lia.
        * auto.
        * now apply andb_true_iff in Hwf.
      + (* Bot. Again, a duplication of the sz=0 case *)
        simpl. repeat rewrite pattern_interpretation_bott_simpl; auto.
      + (* imp *)
        rewrite evar_open_imp.
        simpl in Hsz.
        unfold evar_is_fresh_in in H. simpl in H. apply not_elem_of_union in H. destruct H.
        repeat rewrite -> pattern_interpretation_imp_simpl.
        repeat rewrite <- IHsz.
        * reflexivity.
        * lia.
        * assumption.
        * now apply andb_true_iff in Hwf.
        * lia.
        * auto.
        * now apply andb_true_iff in Hwf.

      + (* ex *)
        rewrite evar_open_exists.
        simpl in Hsz.
        unfold evar_is_fresh_in in H. simpl in H.
        repeat rewrite -> pattern_interpretation_ex_simpl. simpl.
        apply propset_fa_union_same. intros c.
        remember (fresh_evar (bevar_subst phi (patt_free_evar y) (S dbi))) as x'.
        (* rewrite evar_open_bevar_subst_higher.
        { auto. }
        { lia. } *)

        remember (evar_open (S dbi) x phi) as phi'.
        remember (fresh_evar phi') as Xfr'.
        remember (evar_fresh (elements (union (free_evars phi') (singleton x')))) as Xu.

        (* The same destruct as in the mu case of the set substitution lemma *)
        (* destruct (bevar_occur phi (S dbi)) eqn:Hbevar. *)
        --
          rewrite evar_open_bevar_subst_higher.
          { auto. }
          { lia. }
          remember (union (union (union (union
                                           (union (free_evars phi) (free_evars phi'))
                                           (free_evars (bevar_subst phi (patt_free_evar y) (S dbi))))
                                        (singleton Xfr'))
                                 (singleton x))
                          (singleton y))  as B.

          remember (evar_fresh (elements B)) as yB.

          assert (HyBx: yB <> x).
          { solve_fresh_neq. }

          assert (HyBXfr': yB <> Xfr').
          { solve_fresh_neq. }

          assert (HyBy: yB <> y).
          { solve_fresh_neq. }

          assert (HyBfphi: evar_is_fresh_in yB phi).
          {
            subst.
            eapply evar_is_fresh_in_richer'.
            2: apply set_evar_fresh_is_fresh'.
            rewrite <- 4!union_subseteq_l.
            apply union_subseteq_l.
          }

          assert (HyBfphi': evar_is_fresh_in yB phi').
          {
            subst.
            eapply evar_is_fresh_in_richer'.
            2: apply set_evar_fresh_is_fresh'.
            rewrite <- 4!union_subseteq_l.
            apply union_subseteq_r.
          }

          assert (HyBfbevar_open: evar_is_fresh_in yB (bevar_subst phi (patt_free_evar y) (S dbi))).
          { 
            subst.
            eapply evar_is_fresh_in_richer'.
            2: apply set_evar_fresh_is_fresh'.
            rewrite <- 3!union_subseteq_l.
            apply union_subseteq_r.
          }

          rewrite -> interpretation_fresh_evar_open with (x := Xfr') (y := yB).
          3: { apply HyBfphi'. }
          2: { subst. apply set_evar_fresh_is_fresh. }
          
          rewrite update_evar_val_comm.
          { apply HyBx. }
          subst phi'.
          rewrite evar_open_comm_higher.
          { lia. }

          remember (update_evar_val yB c evar_val) as evar_val'.
          remember (evar_open (S dbi) x (evar_open 0 yB phi)) as phi'.

          subst phi'.

          assert (Hevar_val: evar_val y = evar_val' y).
          { subst evar_val'. rewrite update_evar_val_neq. apply HyBy. reflexivity. }
          rewrite Hevar_val.

          rewrite <- IHsz.
          subst evar_val'.
          rewrite <- evar_open_bevar_subst_higher.
          rewrite <- evar_open_bevar_subst_higher.
          rewrite -> interpretation_fresh_evar_open with (y := yB).
          reflexivity.

          { rewrite Heqx'. apply set_evar_fresh_is_fresh. }
          { apply HyBfbevar_open. }
          { auto. }
          { lia. }
          { auto. }
          { lia. }
          { rewrite <- evar_open_size. lia. }
          { apply evar_is_fresh_in_evar_open. apply not_eq_sym. apply HyBx. apply H. }
          { replace (pred (S dbi)) with dbi by lia. apply wfc_mu_aux_body_ex_imp3; auto. lia. }
      + rewrite evar_open_mu.
        rewrite 2!pattern_interpretation_mu_simpl. simpl.
        apply f_equal. apply functional_extensionality. intros x0.
        (* fold (evar_open dbi y phi). *)
        remember (evar_open dbi x phi) as phi'.
        remember (fresh_svar phi') as Xfr'.
        remember (svar_fresh (elements (free_svars phi'))) as Xu.
        remember (update_evar_val x (evar_val y) evar_val) as evar_val'.
        pose proof (Hfresh_subst := @interpretation_fresh_svar_open M phi' Xfr' Xu x0 0 evar_val' svar_val).
        rewrite -> Hfresh_subst.
        2: { subst Xfr'. apply set_svar_fresh_is_fresh. }
        2: { subst Xu. apply set_svar_fresh_is_fresh'. }

        remember (update_svar_val (fresh_svar (bevar_subst phi (patt_free_evar y) dbi)) x0 svar_val) as svar_val1'.
        remember (update_svar_val Xu x0 svar_val) as svar_val2'.
        rewrite -> svar_open_bevar_subst. 2: auto.
        remember (fresh_svar (bevar_subst phi (patt_free_evar y) dbi)) as Xfr1.
        
        (* dbi may or may not occur in phi1 *)
        remember (bevar_occur phi dbi) as Hoc.
        move: HeqHoc.
        case: Hoc => HeqHoc.
        -- (* dbi ocurs in phi1 *)
          pose proof (HXfr1Fresh := @set_svar_fresh_is_fresh signature (bevar_subst phi (patt_free_evar y) dbi)).
          rewrite <- HeqXfr1 in HXfr1Fresh.
          symmetry in HeqHoc.
          pose proof (Hsub := @bevar_subst_contains_subformula signature phi (patt_free_evar y) dbi HeqHoc).
          pose proof (HXfr1Fresh2 := svar_fresh_in_subformula Hsub HXfr1Fresh).

          assert (HXu: (Xfr1 = Xu)).
          { subst Xfr1. subst Xu. subst phi'. unfold fresh_svar.
            rewrite -> free_svars_bevar_subst_eq.          
            rewrite -> free_svars_evar_open.
            assert (Hsvev: free_svars (patt_free_evar y) = ∅) by auto.
            rewrite Hsvev.
            rewrite union_empty_r_L.
            reflexivity.
            assumption.
          }

          rewrite -> HXu in *.
          assert (Hs1s2 : svar_val1' = svar_val2').
          { subst. auto. }
          rewrite Hs1s2.
          subst svar_val2'.
          subst evar_val'.
          assert (Hs1s1': update_svar_val Xu x0 svar_val1' = update_svar_val Xu x0 svar_val).
          { subst. rewrite update_svar_val_shadow. reflexivity. }

          subst phi'.
          rewrite <- svar_open_evar_open_comm.

          rewrite <- IHsz.
        * reflexivity.
        * rewrite <- svar_open_size. simpl in Hsz. lia.
        * apply evar_fresh_svar_open. apply evar_is_fresh_in_mu. apply H.
        * apply wfc_ex_aux_body_mu_imp1. eapply well_formed_closed_ex_aux_ind.
          2: exact Hwf. auto.

          -- (* dbi does not occur in phi1 *)
            pose proof (HeqHoc' := HeqHoc).
            rewrite -> bevar_subst_not_occur.
            (* Now svar_open does nothing to phi1, since it does not contain dbi (see HeqHoc). *)
            (* symmetry in HeqHoc. apply evar_open_not_occur with (x1:=x) in HeqHoc. *)
            (* X is not free in phi1, so the fact that in evar_val' it is updated to some 
           value is irrelevant. *)
            assert (Hpi: pattern_interpretation evar_val svar_val2' (svar_open 0 Xu phi')
                         = pattern_interpretation evar_val' svar_val2' (svar_open 0 Xu phi')).
            { subst evar_val'. rewrite pattern_interpretation_free_evar_independent; auto.
              unfold evar_is_fresh_in.
              rewrite -> free_evars_svar_open. subst phi'.
              rewrite evar_open_not_occur; auto.
              simpl in Hwf. apply wfc_ex_lower; auto.
            }
            rewrite <- Hpi. subst phi'. rewrite evar_open_not_occur; auto.
            { apply wfc_ex_lower; auto. }
            subst svar_val1'. subst svar_val2'.
            rewrite -> interpretation_fresh_svar_open with (Y := Xu). reflexivity.
            { subst Xfr1.
              simpl in Hwf. symmetry in HeqHoc'.
              apply wfc_ex_lower in Hwf; auto.
              pose proof (Hsubst := @bevar_subst_not_occur _ _ (patt_free_evar y) _ Hwf).
              rewrite Hsubst; auto.
            }
            { pose proof (Hfr := set_svar_fresh_is_fresh').
              specialize (Hfr (free_svars (evar_open dbi x phi))).
              subst Xu.
              rewrite free_svars_evar_open in Hfr.
              rewrite free_svars_evar_open. auto.
            }
            { apply wfc_ex_aux_body_mu_imp1.
              apply wfc_ex_lower; auto.
            }
  Qed.

  Lemma element_substitution_lemma
        (M : Model) (phi : Pattern) (x y : evar) (evar_val : EVarVal) (svar_val : SVarVal) (dbi : db_index) :
    evar_is_fresh_in x phi -> well_formed_closed_ex_aux phi (S dbi) ->
    pattern_interpretation evar_val svar_val (bevar_subst phi (patt_free_evar y) dbi)
    = @pattern_interpretation M
                              (update_evar_val x (evar_val y) evar_val)
                              svar_val
                              (evar_open dbi x phi).
  Proof.
    intros.
    apply Private_plugging_patterns_bevar_subst with (sz := size phi);auto.
  Qed.

  (* pattern_interpretation unchanged within subformula over fresh element variable *)
  Lemma interpretation_fresh_evar_subterm M ϕ₁ ϕ₂ c dbi ρₑ ρ :
    is_subformula_of_ind ϕ₁ ϕ₂ ->
    @pattern_interpretation M (update_evar_val (fresh_evar ϕ₂) c ρₑ) ρ (evar_open dbi (fresh_evar ϕ₂) ϕ₁)
    = @pattern_interpretation M (update_evar_val (fresh_evar ϕ₁) c ρₑ) ρ (evar_open dbi (fresh_evar ϕ₁) ϕ₁).
  Proof.
    intros Hsub.
    apply interpretation_fresh_evar_open; auto.
    eapply evar_fresh_in_subformula. apply Hsub.
    apply set_evar_fresh_is_fresh.
  Qed.

  (* model predicate of evar_open is maintained with change of variables *)
  Lemma M_predicate_evar_open_fresh_evar_1 M x₁ x₂ ϕ :
    evar_is_fresh_in x₁ ϕ ->
    evar_is_fresh_in x₂ ϕ ->
    M_predicate M (evar_open 0 x₁ ϕ) ->
    M_predicate M (evar_open 0 x₂ ϕ).
  Proof.
    intros Hfr1 Hfr2.
    unfold evar_is_fresh_in in *.
    unfold M_predicate.
    intros H ρₑ ρₛ.
    rewrite -(@update_evar_val_same_2 M x₂ ρₑ).
    rewrite (@interpretation_fresh_evar_open M _ x₂ x₁); auto.
  Qed.

  Lemma M_predicate_evar_open_fresh_evar_2 M x ϕ :
    evar_is_fresh_in x ϕ ->
    M_predicate M (evar_open 0 (fresh_evar ϕ) ϕ) ->
    M_predicate M (evar_open 0 x ϕ).
  Proof.
    intros Hfr H.
    apply M_predicate_evar_open_fresh_evar_1 with (x₁ := fresh_evar ϕ); auto.
  Qed.

  (* Similar to plugging_patterns: using free svar substitution instead of 
     bound svar substitution.
     TODO: we may be able to gneeralize this lemma to non-closed psi,
           if we deal with nest_mu properly
   *)
  Lemma Private_free_svar_subst_update_exchange {m : Model}: ∀ sz phi psi X svar_val evar_val,
      le (Syntax.size phi) sz → well_formed psi → well_formed_closed phi → 
      pattern_interpretation evar_val svar_val (free_svar_subst phi psi X) =
      pattern_interpretation evar_val
                             (@update_svar_val m X (pattern_interpretation evar_val svar_val psi) svar_val)
                             phi.
  Proof.
    unfold free_svar_subst.
    induction sz; destruct phi; intros psi X svar_val evar_val Hsz Hwf Hwfc ; simpl in *; try inversion Hsz; auto.
    - rewrite -> pattern_interpretation_free_svar_simpl. unfold update_svar_val.
      simpl.
      destruct (decide (X = x)); simpl.
      + reflexivity.
      + rewrite -> pattern_interpretation_free_svar_simpl. reflexivity.
    -  rewrite -> pattern_interpretation_free_svar_simpl. unfold update_svar_val.
      destruct (decide (X = x)); simpl.
      + reflexivity.
      + rewrite -> pattern_interpretation_free_svar_simpl. reflexivity.
    - repeat rewrite -> pattern_interpretation_app_simpl.
      erewrite -> IHsz. erewrite -> IHsz. reflexivity. lia. assumption.
      + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
      + lia.
      + auto.
      + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
    - repeat rewrite -> pattern_interpretation_app_simpl.
      erewrite -> IHsz. erewrite -> IHsz. reflexivity. lia. assumption.
       + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
      + lia.
      + auto.
      + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
    - repeat rewrite -> pattern_interpretation_imp_simpl.
      erewrite -> IHsz. erewrite -> IHsz. reflexivity. lia. assumption.
       + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
      + lia.
      + auto.
      + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
    - repeat rewrite -> pattern_interpretation_imp_simpl.
      erewrite -> IHsz. erewrite -> IHsz. reflexivity. lia. assumption.
       + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
      + lia.
      + auto.
      + apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
        apply andb_true_iff in Hwfc1 as [Hwfc11 Hwfc12].
        apply andb_true_iff in Hwfc2 as [Hwfc21 Hwfc22].
        apply andb_true_iff. split; auto.
    - repeat rewrite -> pattern_interpretation_ex_simpl. simpl.
      apply propset_fa_union_same. intros.
      rewrite -> set_eq_subseteq.
      repeat rewrite -> elem_of_subseteq.
      split.
      + intros.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh  (elements B)) as fresh.
        assert(evar_is_fresh_in (fresh_evar (free_svar_subst phi psi X)) (free_svar_subst phi psi X)).
        {
          apply set_evar_fresh_is_fresh.
        }
        assert(fresh ∉ B).
        {
          subst. apply set_evar_fresh_is_fresh'.
        }
        subst fresh. subst B. apply not_elem_of_union in H2. destruct H2.
        apply not_elem_of_union in H2. destruct H2.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in fresh (free_svar_subst phi psi X)).
        {
          unfold evar_is_fresh_in. assumption.
        }
        erewrite interpretation_fresh_evar_open in H.
        3: { eassumption. }
        2: { assumption. }

        assert(evar_is_fresh_in fresh phi).
        {
          unfold evar_is_fresh_in. assumption.
        }
        assert(evar_is_fresh_in (fresh_evar phi) phi).
        {
          apply set_evar_fresh_is_fresh.
        }
        epose (interpretation_fresh_evar_open c 0 evar_val (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val) _ _) as HFresh.
        rewrite -> HFresh.
        clear HFresh.
        epose (IHsz (evar_open 0 fresh phi) 
                    psi X svar_val 
                    (update_evar_val fresh c evar_val) _ _ ).
        pose (@pattern_interpretation_free_evar_independent m evar_val svar_val fresh c psi).
        rewrite -> e0 in e. clear e0.
        unfold free_svar_subst in *.
        rewrite -> (@evar_open_free_svar_subst_comm) in H.
        unfold free_svar_subst in *.
        rewrite -> e in H.
        all: auto.
        * exact H.
        * apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_ex_imp1.
          -- now apply wfc_ex_aux_body_ex_imp1.
        * apply andb_true_iff in Hwf as [_ Hwf]. apply andb_true_iff in Hwf as [_ Hwf]. apply Hwf.
      + intros.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in (fresh_evar (free_svar_subst phi psi X)) (free_svar_subst phi psi X)).
        {
          apply set_evar_fresh_is_fresh.
        }
        assert(fresh ∉ B).
        {
          subst. apply set_evar_fresh_is_fresh'.
        }
        subst fresh. subst B. apply not_elem_of_union in H2. destruct H2.
        apply not_elem_of_union in H2. destruct H2.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in fresh (free_svar_subst phi psi X)).
        {
          unfold evar_is_fresh_in. assumption.
        }
        erewrite -> interpretation_fresh_evar_open.
        3: { eassumption. }
        2: { assumption. }
        assert(evar_is_fresh_in fresh phi).
        {
          unfold evar_is_fresh_in. assumption.
        }
        assert(evar_is_fresh_in (fresh_evar phi) phi).
        {
          apply set_evar_fresh_is_fresh.
        }
        epose (interpretation_fresh_evar_open c 0 evar_val (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val) _ _) as HFresh.
        rewrite -> HFresh in H.
        clear HFresh.
        epose (IHsz (evar_open 0 fresh phi) 
                    psi X svar_val 
                    (update_evar_val fresh c evar_val) _ _ ).
        pose (@pattern_interpretation_free_evar_independent m evar_val svar_val fresh c psi).
        rewrite -> e0 in e. clear e0. fold free_svar_subst.
        
        rewrite -> (evar_open_free_svar_subst_comm).
        unfold free_svar_subst.
        rewrite -> e.
        all: auto.
        * exact H.
        * apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_ex_imp1.
          -- now apply wfc_ex_aux_body_ex_imp1.
        * apply andb_true_iff in Hwf as [_ Hwf]. apply andb_true_iff in Hwf as [_ Hwf]. apply Hwf.
    - repeat rewrite -> pattern_interpretation_ex_simpl. simpl.
      apply propset_fa_union_same. intros.
      rewrite -> set_eq_subseteq.
      repeat rewrite -> elem_of_subseteq.
      split.
      + intros.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in (fresh_evar (free_svar_subst phi psi X)) (free_svar_subst phi psi X)).
        {
          apply set_evar_fresh_is_fresh.
        }
        assert(fresh ∉ B).
        {
          subst. apply set_evar_fresh_is_fresh'.
        }
        subst fresh. subst B. apply not_elem_of_union in H3. destruct H3.
        apply not_elem_of_union in H3. destruct H3.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in fresh (free_svar_subst phi psi X)).
        {
          unfold evar_is_fresh_in. assumption.
        }
        
        epose proof (interpretation_fresh_evar_open c 0 evar_val svar_val
                                                    H2 H3) as HFresh.
        unfold free_svar_subst in HFresh.
        rewrite -> HFresh in H1.
        clear HFresh.
        assert(evar_is_fresh_in fresh phi).
        {
          unfold evar_is_fresh_in. assumption.
        }
        assert(evar_is_fresh_in (fresh_evar phi) phi).
        {
          apply set_evar_fresh_is_fresh.
        }
        epose (interpretation_fresh_evar_open c 0 evar_val (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val) _ _) as HFresh.
        rewrite -> HFresh.
        clear HFresh.
        epose (IHsz (evar_open 0 fresh phi) 
                    psi X svar_val 
                    (update_evar_val fresh c evar_val) _ _ ).
        pose (@pattern_interpretation_free_evar_independent m evar_val svar_val fresh c psi).
        rewrite -> e0 in e. clear e0. fold free_svar_subst in H1.
        
        rewrite -> (evar_open_free_svar_subst_comm) in H1.
        unfold free_svar_subst in H1.
        rewrite -> e in H1.
        all: auto.
        * exact H1.
        * apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_ex_imp1.
          -- now apply wfc_ex_aux_body_ex_imp1.
        * apply andb_true_iff in Hwf as [_ Hwf]. apply andb_true_iff in Hwf as [_ Hwf]. apply Hwf.
      + intros.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in (fresh_evar (free_svar_subst phi psi X)) (free_svar_subst phi psi X)).
        {
          apply set_evar_fresh_is_fresh.
        }
        assert(fresh ∉ B).
        {
          subst. apply set_evar_fresh_is_fresh'.
        }
        subst fresh. subst B. apply not_elem_of_union in H3. destruct H3.
        apply not_elem_of_union in H3. destruct H3.
        remember ((free_evars (free_svar_subst phi psi X)) ∪ (free_evars phi) ∪ (free_evars psi)) as B.
        remember (evar_fresh (elements B)) as fresh.
        assert(evar_is_fresh_in fresh (free_svar_subst phi psi X)).
        {
          unfold evar_is_fresh_in. assumption.
        }
        epose (interpretation_fresh_evar_open c 0 evar_val svar_val
                                              H2 H3) as HFresh.
        fold free_svar_subst.
        rewrite -> HFresh.
        clear HFresh.
        assert(evar_is_fresh_in fresh phi).
        {
          unfold evar_is_fresh_in. assumption.
        }
        assert(evar_is_fresh_in (fresh_evar phi) phi).
        {
          apply set_evar_fresh_is_fresh.
        }
        epose proof (interpretation_fresh_evar_open c 0 evar_val (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val) _ _) as HFresh.
        rewrite -> HFresh in H1.
        clear HFresh.
        epose (IHsz (evar_open 0 fresh phi) 
                    psi X svar_val 
                    (update_evar_val fresh c evar_val) _ _ ).
        pose (@pattern_interpretation_free_evar_independent m evar_val svar_val fresh c psi).
        rewrite -> e0 in e. clear e0.
        rewrite -> (evar_open_free_svar_subst_comm).
        unfold free_svar_subst.
        rewrite -> e.
        all: auto.
        * exact H1.
        * apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_ex_imp1.
          -- now apply wfc_ex_aux_body_ex_imp1.
        * apply andb_true_iff in Hwf as [_ Hwf]. apply andb_true_iff in Hwf as [_ Hwf]. apply Hwf.
    - repeat rewrite -> pattern_interpretation_mu_simpl. simpl.
      assert ((λ S : propset (Domain m),
                     pattern_interpretation evar_val
                                            (update_svar_val (fresh_svar (free_svar_subst phi psi X)) S svar_val)
                                            (svar_open 0 (fresh_svar (free_svar_subst phi psi X)) (free_svar_subst phi psi X))) =
              (λ S : propset (Domain m),
                     pattern_interpretation evar_val
                                            (update_svar_val (fresh_svar phi) S
                                                             (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val))
                                            (svar_open 0 (fresh_svar phi) phi))).
      apply functional_extensionality. intros.
      + (*Create a common fresh var.*)
        remember ((free_svars phi) ∪ (free_svars psi) ∪ (free_svars (free_svar_subst phi psi X)) ∪ 
                                   (free_svars (patt_free_svar X))) as B.
        remember (svar_fresh (elements B)) as MuZ.
        remember (fresh_svar phi) as MuX.
        remember (fresh_svar (free_svar_subst phi psi X)) as MuY.
        assert(MuZ ∉ B).
        {
          subst. apply set_svar_fresh_is_fresh'.
        }
        subst B. apply not_elem_of_union in H. destruct H.
        apply not_elem_of_union in H. destruct H.
        apply not_elem_of_union in H. destruct H.
        erewrite -> (@interpretation_fresh_svar_open m _ MuX MuZ); try assumption.
        erewrite -> (@interpretation_fresh_svar_open m _ MuY MuZ); try assumption.
        erewrite -> svar_open_free_svar_subst_comm; try assumption.
        rewrite update_svar_val_comm; try assumption. 
        {
          simpl in H1. apply not_elem_of_singleton_1 in H1. assumption.
        }
        epose (IHsz (svar_open 0 MuZ phi) psi X 
                    (update_svar_val MuZ x svar_val) evar_val _ _ _).
        rewrite e. 
        erewrite (@pattern_interpretation_free_svar_independent m _ _ MuZ x psi).
        reflexivity.
        all: auto.
        {
          apply andb_true_iff in Hwf as [_ Hwf]. apply andb_true_iff in Hwf as [Hwf _]. apply Hwf.
        }
        {
          simpl in H1. apply not_elem_of_singleton_1 in H1. assumption.
        }
        {
          subst MuY. apply set_svar_fresh_is_fresh.
        }
        {
          subst MuX. apply set_svar_fresh_is_fresh.
        }
      + fold free_svar_subst. rewrite H. reflexivity.
        (* replace 1 with (0 + 1) by lia.
        rewrite -free_svar_subst_nest_mu_1.
        rewrite nest_mu_aux_wfc_mu.
        { unfold well_formed,well_formed_closed in Hwf. destruct_and!. assumption. }
        rewrite H. reflexivity. *)
    - repeat rewrite -> pattern_interpretation_mu_simpl. simpl.
      assert ((λ S : propset (Domain m),
                     pattern_interpretation evar_val
                                            (update_svar_val (fresh_svar (free_svar_subst phi psi X)) S svar_val)
                                            (svar_open 0 (fresh_svar (free_svar_subst phi psi X)) (free_svar_subst phi psi X))) =
              (λ S : propset (Domain m),
                     pattern_interpretation evar_val
                                            (update_svar_val (fresh_svar phi) S
                                                             (update_svar_val X (pattern_interpretation evar_val svar_val psi) svar_val))
                                            (svar_open 0 (fresh_svar phi) phi))).
      apply functional_extensionality. intros.
      + (*Create a common fresh var.*)
        remember ((free_svars phi) ∪ (free_svars psi) ∪ (free_svars (free_svar_subst phi psi X)) ∪ 
                                   (free_svars (patt_free_svar X))) as B.
        remember (svar_fresh (elements B)) as MuZ.
        remember (fresh_svar phi) as MuX.
        remember (fresh_svar (free_svar_subst phi psi X)) as MuY.
        assert(MuZ ∉ B).
        {
          subst. apply set_svar_fresh_is_fresh'.
        }
        subst B. apply not_elem_of_union in H1. destruct H1.
        apply not_elem_of_union in H1. destruct H1.
        apply not_elem_of_union in H1. destruct H1.
        
        erewrite -> (@interpretation_fresh_svar_open m _ MuX MuZ); try assumption.
        erewrite -> (@interpretation_fresh_svar_open m _ MuY MuZ); try assumption.
        erewrite -> svar_open_free_svar_subst_comm; try assumption.
        rewrite update_svar_val_comm; try assumption. 
        {
          simpl in H2. apply not_elem_of_singleton_1 in H2. assumption.
        }
        epose (IHsz (svar_open 0 MuZ phi) psi X 
                    (update_svar_val MuZ x svar_val) evar_val _ _ ).
        rewrite e. 
        {
          apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_mu_imp1.
          -- now apply wfc_ex_aux_body_mu_imp1.
        }
        erewrite (@pattern_interpretation_free_svar_independent m _ _ MuZ x psi); try assumption.
        reflexivity.
        unfold well_formed,well_formed_closed in Hwf.
        destruct_and!. all: try assumption.
        {
          simpl in H2. apply not_elem_of_singleton_1 in H2. assumption.
        }
        {
          subst MuY. apply set_svar_fresh_is_fresh.
        }
        {
          subst MuX. apply set_svar_fresh_is_fresh.
        }
      + fold free_svar_subst. rewrite H1. reflexivity.
        Unshelve. 
        apply set_evar_fresh_is_fresh.
        assumption.
        {
          subst sz. erewrite <- evar_open_size. reflexivity.
        }
        assumption. apply set_evar_fresh_is_fresh. assumption.
        {
          subst sz. erewrite <- evar_open_size. reflexivity.
        }
        assumption. apply set_evar_fresh_is_fresh. assumption.
        {
          erewrite <- evar_open_size. lia.
        }
        assumption. apply set_evar_fresh_is_fresh. assumption.
        {
          erewrite <- evar_open_size. lia.
        }
        assumption.
        {
          subst sz. erewrite <- svar_open_size. reflexivity.
        }
        assumption.
        { 
          apply andb_true_iff in Hwfc as [Hwfc1 Hwfc2]. simpl in Hwfc1, Hwfc2.
          apply andb_true_iff. split.
          -- now apply wfc_mu_aux_body_mu_imp1.
          -- now apply wfc_ex_aux_body_mu_imp1.
        }
        subst sz. erewrite <- svar_open_size. lia.
        assumption.
  Qed.

  Lemma free_svar_subst_update_exchange {m : Model}: ∀ phi psi X svar_val evar_val,
      well_formed psi → well_formed_closed phi → 
      pattern_interpretation evar_val svar_val (free_svar_subst phi psi X) =
      pattern_interpretation evar_val (@update_svar_val m X 
                                                        (pattern_interpretation evar_val svar_val psi) svar_val) 
                             phi.
  Proof. 
    intros. apply Private_free_svar_subst_update_exchange with (sz := size phi). 
    lia. assumption. assumption.
  Qed.

  (* rho(psi) = empty then C[rho(psi)] = empty *)
  Lemma propagate_context_empty M psi evar_val svar_val C :
    @pattern_interpretation M evar_val svar_val psi = Empty ->
    @pattern_interpretation M evar_val svar_val (subst_ctx C psi) = Empty.
  Proof.
    intro Hpsi. induction C.
    * auto.
    * simpl. rewrite pattern_interpretation_app_simpl. rewrite IHC. apply app_ext_bot_l.
    * simpl. rewrite pattern_interpretation_app_simpl. rewrite IHC. apply app_ext_bot_r.
  Qed.

  (* application to a singleton *)
  Definition rel_of M ρₑ ρ ϕ: Domain M -> propset (Domain M) :=
    λ m₁,
    (app_ext (@pattern_interpretation M ρₑ ρ ϕ) {[ m₁ ]}).

  Definition is_total_function M f (d c : propset (Domain M)) ρₑ ρ :=
    ∀ (m₁ : Domain M),
      m₁ ∈ d ->
      ∃ (m₂ : Domain M),
        m₂ ∈ c /\
        app_ext (@pattern_interpretation M ρₑ ρ f) {[ m₁ ]}
        = {[ m₂ ]}.

  Definition total_function_is_injective M f (d : propset (Domain M)) ρₑ ρ :=
    ∀ (m₁ : Domain M),
      m₁ ∈ d ->
      ∀ (m₂ : Domain M),
        m₂ ∈ d ->
        (rel_of ρₑ ρ f) m₁ = (rel_of ρₑ ρ f) m₂ ->
        m₁ = m₂.

  Definition is_functional_pattern ϕ M ρₑ ρₛ :=
    ∃ (m : Domain M), @pattern_interpretation M ρₑ ρₛ ϕ = {[ m ]}.

  Lemma functional_pattern_inj ϕ M ρₑ ρ m₁ m₂ :
    @is_functional_pattern ϕ M ρₑ ρ ->
    m₁ ∈ @pattern_interpretation M ρₑ ρ ϕ ->
    m₂ ∈ @pattern_interpretation M ρₑ ρ ϕ ->
    m₁ = m₂.
  Proof.
    intros [m Hm] Hm₁ Hm₂.
    rewrite Hm in Hm₁. inversion Hm₁. subst. clear Hm₁.
    rewrite Hm in Hm₂. inversion Hm₂. subst. clear Hm₂.
    reflexivity.
  Qed.

End semantics.


Module Notations.
  Declare Scope ml_scope.
  Delimit Scope ml_scope with ml.
  
  Notation "M ⊨ᴹ phi" := (satisfies_model M phi) (left associativity, at level 50) : ml_scope.
  (* FIXME this should not be called `satisfies` *)
  Notation "G ⊨ phi" := (satisfies G phi) (left associativity, at level 50) : ml_scope.
  Notation "M ⊨ᵀ Gamma" := (satisfies_theory M Gamma)
                             (left associativity, at level 50) : ml_scope.
End Notations.

(*Module Hints.*)
#[export]
 Hint Resolve M_predicate_impl : core.
#[export]
 Hint Resolve M_predicate_bott : core.
#[export]
 Hint Resolve M_predicate_exists : core.
#[export]
 Hint Extern 4 (M_predicate _ (evar_open _ _ _)) => unfold evar_open; rewrite !simpl_bevar_subst' : core.
#[export]
 Hint Extern 4 (T_predicate _ (evar_open _ _ _)) => unfold evar_open; rewrite !simpl_bevar_subst' : core.
#[export]
 Hint Extern 4 (M_predicate _ (svar_open _ _ _)) => unfold svar_open; rewrite !simpl_bsvar_subst' : core.
#[export]
 Hint Extern 4 (T_predicate _ (svar_open _ _ _)) => unfold svar_open; rewrite !simpl_bsvar_subst' : core.
#[export]
 Hint Resolve T_predicate_impl_M_predicate : core.
#[export]
 Hint Resolve T_predicate_impl : core.
#[export]
 Hint Resolve T_predicate_bot : core.
(*End Hints.*)
